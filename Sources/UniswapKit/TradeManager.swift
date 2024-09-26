import BigInt
import EvmKit
import Foundation
import HsCryptoKit
import HsToolKit

class TradeManager {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    private func buildSwapData(receiveAddress: Address, tradeData: TradeData) throws -> SwapData {
        let trade = tradeData.trade

        let tokenIn = trade.tokenAmountIn.token
        let tokenOut = trade.tokenAmountOut.token

        let path = trade.route.path.map(\.address)
        let to = tradeData.options.recipient ?? receiveAddress
        let deadline = BigUInt(Date().timeIntervalSince1970 + tradeData.options.ttl)

        let method: ContractMethod
        var amount: BigUInt

        switch trade.type {
        case .exactIn:
            amount = tokenIn.isEther ? trade.tokenAmountIn.rawAmount : 0
            method = try buildMethodForExactIn(tokenIn: tokenIn, tokenOut: tokenOut, path: path, to: to, deadline: deadline, tradeData: tradeData, trade: trade)
        case .exactOut:
            amount = tokenIn.isEther ? tradeData.tokenAmountInMax.rawAmount : 0
            method = try buildMethodForExactOut(tokenIn: tokenIn, tokenOut: tokenOut, path: path, to: to, deadline: deadline, tradeData: tradeData)
        }

        return SwapData(amount: amount, input: method.encodedABI())
    }

    private func buildMethodForExactOut(tokenIn: Token, tokenOut: Token, path: [Address], to: Address, deadline: BigUInt, tradeData: TradeData) throws -> ContractMethod {
        let amountInMax = tradeData.tokenAmountInMax.rawAmount
        let amountOut = tradeData.trade.tokenAmountOut.rawAmount

        guard tokenIn != tokenOut else {
            throw Kit.TradeError.invalidTokensForSwap
        }

        switch tokenIn {
        case .eth: return SwapETHForExactTokensMethod(amountOut: amountOut, path: path, to: to, deadline: deadline)
        case .erc20:
            if case .eth = tokenOut {
                return SwapTokensForExactETHMethod(amountOut: amountOut, amountInMax: amountInMax, path: path, to: to, deadline: deadline)
            }
            return SwapTokensForExactTokensMethod(amountOut: amountOut, amountInMax: amountInMax, path: path, to: to, deadline: deadline)
        }
    }

    private func buildMethodForExactIn(tokenIn: Token, tokenOut: Token, path: [Address], to: Address, deadline: BigUInt, tradeData: TradeData, trade: Trade) throws -> ContractMethod {
        let amountIn = trade.tokenAmountIn.rawAmount
        let amountOutMin = tradeData.tokenAmountOutMin.rawAmount
        let supportingFeeOnTransfer = tradeData.options.feeOnTransfer

        guard tokenIn != tokenOut else {
            throw Kit.TradeError.invalidTokensForSwap
        }

        switch tokenIn {
        case .eth: return SwapExactETHForTokensMethod(amountOut: amountOutMin, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: supportingFeeOnTransfer)
        case .erc20:
            if case .eth = tokenOut {
                return SwapExactTokensForETHMethod(amountIn: amountIn, amountOutMin: amountOutMin, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: supportingFeeOnTransfer)
            }
            return SwapExactTokensForTokensMethod(amountIn: amountIn, amountOutMin: amountOutMin, path: path, to: to, deadline: deadline, supportingFeeOnTransfer: supportingFeeOnTransfer)
        }
    }
}

extension TradeManager {
    func pair(rpcSource: RpcSource, chain: Chain, tokenA: Token, tokenB: Token) async throws -> Pair {
        let (token0, token1) = tokenA.sortsBefore(token: tokenB) ? (tokenA, tokenB) : (tokenB, tokenA)

        let pairAddress = try Pair.address(
            token0: token0, token1: token1,
            factoryAddressString: Self.factoryAddressString(chain: chain),
            initCodeHashString: Self.initCodeHashString(chain: chain)
        )

//        print("PAIR ADDRESS: \(pairAddress.toHexString())")

        let data = try await EvmKit.Kit.call(networkManager: networkManager, rpcSource: rpcSource, contractAddress: pairAddress, data: GetReservesMethod().encodedABI())
//        print("DATA: \(data.toHexString())")

        var rawReserve0: BigUInt = 0
        var rawReserve1: BigUInt = 0

        if data.count == 3 * 32 {
            rawReserve0 = BigUInt(data[0 ... 31])
            rawReserve1 = BigUInt(data[32 ... 63])
        }

//        print("Reserve0: \(reserve0), Reserve1: \(reserve1)")

        let reserve0 = TokenAmount(token: token0, rawAmount: rawReserve0)
        let reserve1 = TokenAmount(token: token1, rawAmount: rawReserve1)

        return Pair(reserve0: reserve0, reserve1: reserve1)
    }

    func transactionData(receiveAddress: Address, chain: Chain, tradeData: TradeData) throws -> TransactionData {
        let swapData = try buildSwapData(receiveAddress: receiveAddress, tradeData: tradeData)

        return try TransactionData(
            to: Self.routerAddress(chain: chain),
            value: swapData.amount,
            input: swapData.input
        )
    }
}

extension TradeManager {
    private struct SwapData {
        let amount: BigUInt
        let input: Data
    }

    public enum UnsupportedChainError: Error {
        case noRouterAddress
        case noFactoryAddress
        case noInitCodeHash
    }
}

extension TradeManager {
    static func tradesExactIn(pairs: [Pair], tokenAmountIn: TokenAmount, tokenOut: Token, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountIn: TokenAmount? = nil) throws -> [Trade] {
        // TODO: guards

        var trades = [Trade]()
        let originalTokenAmountIn = originalTokenAmountIn ?? tokenAmountIn

        for (index, pair) in pairs.enumerated() {
            let tokenAmountOut: TokenAmount

            do {
                tokenAmountOut = try pair.tokenAmountOut(tokenAmountIn: tokenAmountIn)
            } catch {
                continue
            }

            if tokenAmountOut.token == tokenOut {
                let trade = try Trade(
                    type: .exactIn,
                    route: Route(pairs: currentPairs + [pair], tokenIn: originalTokenAmountIn.token, tokenOut: tokenOut),
                    tokenAmountIn: originalTokenAmountIn,
                    tokenAmountOut: tokenAmountOut
                )

                trades.append(trade)
            } else if maxHops > 1, pairs.count > 1 {
                let pairsExcludingThisPair = Array(pairs[0 ..< index] + pairs[(index + 1) ..< pairs.count])

                let recursiveTrades = try TradeManager.tradesExactIn(
                    pairs: pairsExcludingThisPair,
                    tokenAmountIn: tokenAmountOut,
                    tokenOut: tokenOut,
                    maxHops: maxHops - 1,
                    currentPairs: currentPairs + [pair],
                    originalTokenAmountIn: originalTokenAmountIn
                )

                trades.append(contentsOf: recursiveTrades)
            }
        }

        return trades
    }

    static func tradesExactOut(pairs: [Pair], tokenIn: Token, tokenAmountOut: TokenAmount, maxHops: Int = 3, currentPairs: [Pair] = [], originalTokenAmountOut: TokenAmount? = nil) throws -> [Trade] {
        // TODO: guards

        var trades = [Trade]()
        let originalTokenAmountOut = originalTokenAmountOut ?? tokenAmountOut

        for (index, pair) in pairs.enumerated() {
            let tokenAmountIn: TokenAmount

            do {
                tokenAmountIn = try pair.tokenAmountIn(tokenAmountOut: tokenAmountOut)
            } catch {
                continue
            }

            if tokenAmountIn.token == tokenIn {
                let trade = try Trade(
                    type: .exactOut,
                    route: Route(pairs: [pair] + currentPairs, tokenIn: tokenIn, tokenOut: originalTokenAmountOut.token),
                    tokenAmountIn: tokenAmountIn,
                    tokenAmountOut: originalTokenAmountOut
                )

                trades.append(trade)
            } else if maxHops > 1, pairs.count > 1 {
                let pairsExcludingThisPair = Array(pairs[0 ..< index] + pairs[(index + 1) ..< pairs.count])

                let recursiveTrades = try TradeManager.tradesExactOut(
                    pairs: pairsExcludingThisPair,
                    tokenIn: tokenIn,
                    tokenAmountOut: tokenAmountIn,
                    maxHops: maxHops - 1,
                    currentPairs: [pair] + currentPairs,
                    originalTokenAmountOut: originalTokenAmountOut
                )

                trades.append(contentsOf: recursiveTrades)
            }
        }

        return trades
    }

    static func routerAddress(chain: Chain) throws -> Address {
        switch chain {
        case .ethereum, .ethereumRopsten, .ethereumRinkeby, .ethereumKovan, .ethereumGoerli: return try Address(hex: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
        case .binanceSmartChain: return try Address(hex: "0x10ED43C718714eb63d5aA57B78B54704E256024E")
        case .polygon: return try Address(hex: "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff")
        case .avalanche: return try Address(hex: "0x60aE616a2155Ee3d9A68541Ba4544862310933d4")
        case .base: return try Address(hex: "0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24")
        default: throw UnsupportedChainError.noRouterAddress
        }
    }

    private static func factoryAddressString(chain: Chain) throws -> String {
        switch chain {
        case .ethereum, .ethereumRopsten, .ethereumRinkeby, .ethereumKovan, .ethereumGoerli: return "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
        case .binanceSmartChain: return "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73"
        case .polygon: return "0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32"
        case .avalanche: return "0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10"
        case .base: return "0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6"
        default: throw UnsupportedChainError.noFactoryAddress
        }
    }

    private static func initCodeHashString(chain: Chain) throws -> String {
        switch chain {
        case .ethereum, .ethereumRopsten, .ethereumRinkeby, .ethereumKovan, .ethereumGoerli, .polygon, .avalanche, .base: return "0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f"
        case .binanceSmartChain: return "0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5"
        default: throw UnsupportedChainError.noInitCodeHash
        }
    }
}
