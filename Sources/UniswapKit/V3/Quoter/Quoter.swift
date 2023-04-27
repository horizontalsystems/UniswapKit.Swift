import Foundation
import EvmKit
import BigInt

public class Quoter {
    private let quoterAddress = try! Address(hex: "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6") // for all supported
    private let evmKit: EvmKit.Kit
    private let tokenFactory: TokenFactory

    init(evmKit: EvmKit.Kit, tokenFactory: TokenFactory) {
        self.evmKit = evmKit
        self.tokenFactory = tokenFactory
    }

    private func quoteExact(tradeType: TradeType, tokenIn: Address, tokenOut: Address, amount: BigUInt, fee: KitV3.FeeAmount) async throws -> BigUInt {
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
        let data = try await call(data: method.encodedABI())
        guard data.count >= 32 else {
            throw KitV3.TradeError.tradeNotFound
        }

        return BigUInt(data[0...31])
    }

    private func quote(swapPath: SwapPath, amount: BigUInt) async throws -> BigUInt {
        let method = swapPath.tradeType == .exactIn ?
                QuoteExactInputMethod(swapPath: swapPath, amountIn: amount) :
                QuoteExactOutputMethod(swapPath: swapPath, amountOut: amount)

        let data = try await call(data: method.encodedABI())
        guard data.count >= 32 else {
            throw KitV3.TradeError.tradeNotFound
        }

        return BigUInt(data[0...31])
    }

    private func bestTradeExact(tradeType: TradeType, tokenIn: Token, tokenOut: Token, amount: BigUInt, fees: [KitV3.FeeAmount] = KitV3.FeeAmount.allCases, index: Int = 0) async throws -> BestTrade {
        // check all fees and found the best amount for trade.
        var bestTrade: (fee: KitV3.FeeAmount, amount: BigUInt)?
        for fee in fees {
            guard let amount = try? await quoteExact(
                    tradeType: tradeType,
                    tokenIn: tokenIn.address,
                    tokenOut: tokenOut.address,
                    amount: amount,
                    fee: fee
            ) else {
                continue
            }

            // For exactIn - we must found the highest amountOut, for exactOut - smallest amountIn
            if let bestTrade, (tradeType == .exactIn ? bestTrade.amount >= amount : bestTrade.amount <= amount) {
                continue
            }

            bestTrade = (fee: fee, amount: amount)
        }

        guard let bestTrade else {
            throw KitV3.TradeError.tradeNotFound
        }

        let swapPath = SwapPath(tradeType: tradeType, tokenIn: tokenIn, tokenOut: tokenOut, fee: bestTrade.fee)
        return BestTrade(swapPath: swapPath, amount: bestTrade.amount)
    }

    private func bestTradeMultihop(tradeType: TradeType, tokenIn: Token, tokenOut: Token, amount: BigUInt) async throws -> BestTrade {
        let weth = tokenFactory.etherToken

        let tokens = [tokenIn, weth, tokenOut]

        // we get path by pairs. for exactIn it must be A->B, B->C, C->D, but for exactOut opposite: C->D, B->C, A->B
        let pair: (_ index: Int) -> (`in`: Token, out: Token) = { index in
            let firstIndex = tradeType == .exactIn ? index : (tokens.count - index - 2)
            return (tokens[firstIndex], tokens[firstIndex + 1])
        }

        let bestTradeIn = try await bestTradeExact(tradeType: tradeType, tokenIn: pair(0).in, tokenOut: pair(0).out, amount: amount)
        let bestTradeOut = try await bestTradeExact(tradeType: tradeType, tokenIn: pair(1).in, tokenOut: pair(1).out, amount: bestTradeIn.amount)

        let path = try SwapPath(tradeType: tradeType, items: bestTradeIn.swapPath.items + bestTradeOut.swapPath.items)
        let amount = try await quote(swapPath: path, amount: amount)

        return BestTrade(swapPath: path, amount: amount)
    }

    func bestTrade(tradeType: TradeType, tokenIn: Token, tokenOut: Token, amount: BigUInt) async throws -> BestTrade {
        do {
            let trade = try await bestTradeExact(tradeType: tradeType, tokenIn: tokenIn, tokenOut: tokenOut, amount: amount)
            print("New exact trade: \(trade)")
            return trade
        } catch {
            print("error! \(error)")
        }
        do {
            let trade = try await bestTradeMultihop(tradeType: tradeType, tokenIn: tokenIn, tokenOut: tokenOut, amount: amount)
            print("New trade: \(trade)")
            return trade
        } catch {
            print("error! \(error)")
        }
        throw KitV3.TradeError.tradeNotFound
    }


    private func call(data: Data) async throws -> Data {
        print("call : \(Task.isCancelled)")
        do {
            let a = try await evmKit.fetchCall(contractAddress: quoterAddress, data: data)
            return a
        } catch {
            print("Call Error: \(error)")
            throw error
        }
    }

}

extension Quoter {

    func bestTradeExactIn(tokenIn: Token, tokenOut: Token, amountIn: BigUInt) async throws -> BestTrade {
        try await bestTrade(tradeType: .exactIn, tokenIn: tokenIn, tokenOut: tokenOut, amount: amountIn)
    }

    func bestTradeExactOut(tokenIn: Token, tokenOut: Token, amountOut: BigUInt) async throws -> BestTrade {
        try await bestTrade(tradeType: .exactOut, tokenIn: tokenIn, tokenOut: tokenOut, amount: amountOut)
    }

}

extension Quoter {

    public struct BestTrade {
        public let swapPath: SwapPath
        public let amount: BigUInt
    }

}
