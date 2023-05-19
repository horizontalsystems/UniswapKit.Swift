import Foundation
import EvmKit
import BigInt
import Alamofire
import HsToolKit

public class Quoter {
    private let quoterAddress = try! Address(hex: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e") // for all supported //v1 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6
    private let evmKit: EvmKit.Kit
    private let tokenFactory: TokenFactory

    init(evmKit: EvmKit.Kit, tokenFactory: TokenFactory) {
        self.evmKit = evmKit
        self.tokenFactory = tokenFactory
    }

    private func correctedX96Price(sqrtPriceX96: BigUInt, tokenIn: Token, tokenOut: Token) -> Decimal? {
        let reverted = tokenIn.address.hex >= tokenOut.address.hex

        let shift = (tokenIn.decimals - tokenOut.decimals) * (reverted ? -1 : 1)
        guard let price = PriceImpactHelper.price(from: sqrtPriceX96, shift: shift) else {
            return nil
        }

        if reverted {
            return 1 / price
        }
        return price
    }

    private func quoteExact(tradeType: TradeType, tokenIn: Address, tokenOut: Address, amount: BigUInt, fee: KitV3.FeeAmount) async throws -> QuoteExactSingleResponse {
        let method = tradeType == .exactIn ?
                QuoteExactInputSingleMethod(
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        fee: fee,
                        amountIn: amount,
                        sqrtPriceLimitX96: 0) :
                QuoteExactOutputSingleMethod(
                        tokenIn: tokenIn,
                        tokenOut: tokenOut,
                        fee: fee,
                        amountOut: amount,
                        sqrtPriceLimitX96: 0)

        do {
            let data = try await call(data: method.encodedABI())
            guard let response = QuoteExactSingleResponse(data: data) else {
                throw KitV3.TradeError.tradeNotFound
            }

            return response
        } catch {
            if error.isExplicitlyCancelled {    // throw cancellation for stop requests
                throw error
            }

            throw KitV3.TradeError.tradeNotFound
        }
    }

    private func quote(swapPath: SwapPath, tradeType: TradeType, amount: BigUInt) async throws -> BigUInt {
        let method = tradeType == .exactIn ?
                QuoteExactInputMethod(swapPath: swapPath, amountIn: amount) :
                QuoteExactOutputMethod(swapPath: swapPath, amountOut: amount)

        let data = try await call(data: method.encodedABI())
        guard data.count >= 32 else {
            throw KitV3.TradeError.tradeNotFound
        }

        return BigUInt(data[0...31])
    }

    private func bestTradeExact(tradeType: TradeType, tokenIn: Token, tokenOut: Token, amount: BigUInt, fees: [KitV3.FeeAmount] = KitV3.FeeAmount.allCases) async throws -> (fee: KitV3.FeeAmount, response: QuoteExactSingleResponse) {
        // check all fees and found the best amount for trade.
        var bestTrade: (fee: KitV3.FeeAmount, response: QuoteExactSingleResponse)?
        for fee in fees {
            do {
                let response = try await quoteExact(
                        tradeType: tradeType,
                        tokenIn: tokenIn.address,
                        tokenOut: tokenOut.address,
                        amount: amount,
                        fee: fee
                )
                // For exactIn - we must found the highest amountOut, for exactOut - smallest amountIn
                if let bestTrade, (tradeType == .exactIn ? bestTrade.response.amount >= response.amount : bestTrade.response.amount <= response.amount) {
                    continue
                }

                bestTrade = (fee: fee, response: response)
            } catch {
                if case .tradeNotFound = error as? KitV3.TradeError {
                    continue
                }
                throw error
            }
        }

        guard let bestTrade else {
            throw KitV3.TradeError.tradeNotFound
        }

        return bestTrade
    }

    private func bestTradeSingleIn(tokenIn: Token, tokenOut: Token, amountIn: BigUInt) async throws -> TradeV3 {
        let bestTradeOut = try await bestTradeExact(tradeType: .exactIn, tokenIn: tokenIn, tokenOut: tokenOut, amount: amountIn)

        let pool = try await Pool(evmKit: evmKit, token0: tokenIn.address, token1: tokenOut.address, fee: bestTradeOut.fee)
        let sqrtPriceX96 = try await pool.slot0().sqrtPriceX96
        let slotPrice = correctedX96Price(
                sqrtPriceX96: sqrtPriceX96,
                tokenIn: tokenIn,
                tokenOut: tokenOut
        )

        let swapPath = SwapPath([SwapPathItem(token1: tokenIn.address, token2: tokenOut.address, fee: bestTradeOut.fee)])
        return TradeV3(tradeType: .exactIn, swapPath: swapPath, amountIn: amountIn, amountOut: bestTradeOut.response.amount, tokenIn: tokenIn, tokenOut: tokenOut, slotPrices: slotPrice.map { [$0] } ?? [])
    }

    private func bestTradeSingleOut(tokenIn: Token, tokenOut: Token, amountOut: BigUInt) async throws -> TradeV3 {
        let bestTradeIn = try await bestTradeExact(tradeType: .exactOut, tokenIn: tokenIn, tokenOut: tokenOut, amount: amountOut)

        let pool = try await Pool(evmKit: evmKit, token0: tokenIn.address, token1: tokenOut.address, fee: bestTradeIn.fee)
        let sqrtPriceX96 = try await pool.slot0().sqrtPriceX96
        let slotPrice = correctedX96Price(
                sqrtPriceX96: sqrtPriceX96,
                tokenIn: tokenIn,
                tokenOut: tokenOut
        )

        let swapPath = SwapPath([SwapPathItem(token1: tokenOut.address, token2: tokenIn.address, fee: bestTradeIn.fee)])
        return TradeV3(tradeType: .exactOut, swapPath: swapPath, amountIn: bestTradeIn.response.amount, amountOut: amountOut, tokenIn: tokenIn, tokenOut: tokenOut, slotPrices: slotPrice.map { [$0] } ?? [])
    }

    private func bestTradeMultihopIn(tokenIn: Token, tokenOut: Token, amountIn: BigUInt) async throws -> TradeV3 {
        let weth = tokenFactory.etherToken

        let trade1 = try await bestTradeSingleIn(tokenIn: tokenIn, tokenOut: weth, amountIn: amountIn)
        let trade2 = try await bestTradeSingleIn(tokenIn: weth, tokenOut: tokenOut, amountIn: trade1.tokenAmountOut.rawAmount)

        let path = SwapPath(trade1.swapPath.items + trade2.swapPath.items)
        let amountOut = try await quote(swapPath: path, tradeType: .exactIn, amount: amountIn)

        let slotPrices = [trade1.slotPrices.first, trade2.slotPrices.first].compactMap { $0 }
        return TradeV3(tradeType: .exactIn, swapPath: path, amountIn: amountIn, amountOut: amountOut, tokenIn: tokenIn, tokenOut: tokenOut, slotPrices: slotPrices)
    }

    private func bestTradeMultihopOut(tokenIn: Token, tokenOut: Token, amountOut: BigUInt) async throws -> TradeV3 {
        let weth = tokenFactory.etherToken

        let trade1 = try await bestTradeSingleOut(tokenIn: weth, tokenOut: tokenOut, amountOut: amountOut)
        let trade2 = try await bestTradeSingleOut(tokenIn: tokenIn, tokenOut: weth, amountOut: trade1.tokenAmountIn.rawAmount)

        let path = SwapPath(trade1.swapPath.items + trade2.swapPath.items)
        let amountIn = try await quote(swapPath: path, tradeType: .exactOut, amount: amountOut)


        let slotPrices = [trade1.slotPrices.first, trade2.slotPrices.first].compactMap { $0 }
        return TradeV3(tradeType: .exactIn, swapPath: path, amountIn: amountIn, amountOut: amountOut, tokenIn: tokenIn, tokenOut: tokenOut, slotPrices: slotPrices)
    }

    func bestTrade(tradeType: TradeType, tokenIn: Token, tokenOut: Token, amount: BigUInt) async throws -> TradeV3 {
        do {
            switch tradeType {
            case .exactIn: return try await bestTradeSingleIn(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amount)
            case .exactOut: return try await bestTradeSingleOut(tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amount)
            }
        } catch {
            guard case .tradeNotFound = error as? KitV3.TradeError else {   // ignore 'not found' error, try found other trade
                throw error
            }
        }
        do {
            switch tradeType {
            case .exactIn: return try await bestTradeMultihopIn(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amount)
            case .exactOut: return try await bestTradeMultihopOut(tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amount)
            }
        } catch {
            throw error
        }
    }


    private func call(data: Data) async throws -> Data {
        do {
            let a = try await evmKit.fetchCall(contractAddress: quoterAddress, data: data)
            return a
        } catch {
            throw error
        }
    }

}

extension Quoter {

    func bestTradeExactIn(tokenIn: Token, tokenOut: Token, amountIn: BigUInt) async throws -> TradeV3 {
        try await bestTrade(tradeType: .exactIn, tokenIn: tokenIn, tokenOut: tokenOut, amount: amountIn)
    }

    func bestTradeExactOut(tokenIn: Token, tokenOut: Token, amountOut: BigUInt) async throws -> TradeV3 {
        try await bestTrade(tradeType: .exactOut, tokenIn: tokenIn, tokenOut: tokenOut, amount: amountOut)
    }

}
