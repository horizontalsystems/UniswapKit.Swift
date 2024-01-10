import BigInt
import EvmKit
import Foundation
import HsToolKit

public class Kit {
    private let tradeManager: TradeManager
    private let pairSelector: PairSelector
    private let tokenFactory: TokenFactory

    init(tradeManager: TradeManager, pairSelector: PairSelector, tokenFactory: TokenFactory) {
        self.tradeManager = tradeManager
        self.pairSelector = pairSelector
        self.tokenFactory = tokenFactory
    }
}

public extension Kit {
    func routerAddress(chain: Chain) throws -> Address {
        try TradeManager.routerAddress(chain: chain)
    }

    func etherToken(chain: Chain) throws -> Token {
        try tokenFactory.etherToken(chain: chain)
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        tokenFactory.token(contractAddress: contractAddress, decimals: decimals)
    }

    func swapData(rpcSource: RpcSource, chain: Chain, tokenIn: Token, tokenOut: Token) async throws -> SwapData {
        let tokenPairs = try pairSelector.tokenPairs(chain: chain, tokenA: tokenIn, tokenB: tokenOut)

        let pairs = try await withThrowingTaskGroup(of: Pair.self) { taskGroup in
            tokenPairs.forEach { token, token2 in
                taskGroup.addTask {
                    try await self.tradeManager.pair(rpcSource: rpcSource, chain: chain, tokenA: token, tokenB: token2)
                }
            }

            return try await taskGroup.reduce(into: [Pair]()) { result, pair in
                result.append(pair)
            }
        }

        return SwapData(pairs: pairs, tokenIn: tokenIn, tokenOut: tokenOut)
    }

    func bestTradeExactIn(swapData: SwapData, amountIn: Decimal, options: TradeOptions = TradeOptions()) throws -> TradeData {
        guard amountIn > 0 else {
            throw TradeError.zeroAmount
        }

        let tokenAmountIn = try TokenAmount(token: swapData.tokenIn, decimal: amountIn)

        let sortedTrades = try TradeManager.tradesExactIn(
            pairs: swapData.pairs,
            tokenAmountIn: tokenAmountIn,
            tokenOut: swapData.tokenOut
        ).sorted()

        guard let bestTrade = sortedTrades.first else {
            throw TradeError.tradeNotFound
        }

        return TradeData(trade: bestTrade, options: options)
    }

    func bestTradeExactOut(swapData: SwapData, amountOut: Decimal, options: TradeOptions = TradeOptions()) throws -> TradeData {
        guard amountOut > 0 else {
            throw TradeError.zeroAmount
        }

        let tokenAmountOut = try TokenAmount(token: swapData.tokenOut, decimal: amountOut)

        let sortedTrades = try TradeManager.tradesExactOut(
            pairs: swapData.pairs,
            tokenIn: swapData.tokenIn,
            tokenAmountOut: tokenAmountOut
        ).sorted()

//        print("Trades: \(sortedTrades)")

        guard let bestTrade = sortedTrades.first else {
            throw TradeError.tradeNotFound
        }

        return TradeData(trade: bestTrade, options: options)
    }

    func transactionData(receiveAddress: Address, chain: Chain, tradeData: TradeData) throws -> TransactionData {
        try tradeManager.transactionData(receiveAddress: receiveAddress, chain: chain, tradeData: tradeData)
    }
}

public extension Kit {
    static func instance() throws -> Kit {
        let networkManager = NetworkManager()
        let tradeManager = TradeManager(networkManager: networkManager)
        let tokenFactory = TokenFactory()
        let pairSelector = PairSelector(tokenFactory: tokenFactory)

        let uniswapKit = Kit(tradeManager: tradeManager, pairSelector: pairSelector, tokenFactory: tokenFactory)

        return uniswapKit
    }

    static func addDecorators(to evmKit: EvmKit.Kit) {
        evmKit.add(methodDecorator: SwapMethodDecorator(contractMethodFactories: SwapContractMethodFactories.shared))
        evmKit.add(transactionDecorator: SwapTransactionDecorator())
    }
}

public extension Kit {
    enum FractionError: Error {
        case negativeDecimal
        case invalidSignificand(value: String)
    }

    enum TradeError: Error {
        case zeroAmount
        case tradeNotFound
        case invalidTokensForSwap
    }

    enum PairError: Error {
        case notInvolvedToken
        case insufficientReserves
        case insufficientReserveOut
    }

    enum RouteError: Error {
        case emptyPairs
        case invalidPair(index: Int)
    }
}
