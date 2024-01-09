import BigInt
import EvmKit
import Foundation

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
    var routerAddress: Address {
        tradeManager.routerAddress
    }

    var etherToken: Token {
        tokenFactory.etherToken
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        tokenFactory.token(contractAddress: contractAddress, decimals: decimals)
    }

    func swapData(tokenIn: Token, tokenOut: Token) async throws -> SwapData {
        let tokenPairs = pairSelector.tokenPairs(tokenA: tokenIn, tokenB: tokenOut)

        let pairs = try await withThrowingTaskGroup(of: Pair.self) { taskGroup in
            tokenPairs.forEach { token, token2 in
                taskGroup.addTask { try await self.tradeManager.pair(tokenA: token, tokenB: token2) }
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

    func transactionData(tradeData: TradeData) throws -> TransactionData {
        try tradeManager.transactionData(tradeData: tradeData)
    }
}

public extension Kit {
    static func instance(evmKit: EvmKit.Kit) throws -> Kit {
        let address = evmKit.address

        let tradeManager = try TradeManager(evmKit: evmKit, address: address)
        let tokenFactory = try TokenFactory(chain: evmKit.chain)
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
