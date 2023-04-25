import Foundation
import RxSwift
import EvmKit
import BigInt

public class KitV3 {
    private let disposeBag = DisposeBag()

    private let evmKit: EvmKit.Kit
    private let quoter: Quoter
    private let swapRouter: SwapRouter
    private let tokenFactory: TokenFactory

    init(evmKit: EvmKit.Kit, quoter: Quoter, swapRouter: SwapRouter, tokenFactory: TokenFactory) {
        self.evmKit = evmKit
        self.quoter = quoter
        self.swapRouter = swapRouter
        self.tokenFactory = tokenFactory
    }

}

extension KitV3 {

    public var routerAddress: Address {
        swapRouter.routerAddress
    }

    public var etherToken: Token {
        tokenFactory.etherToken
    }

    public func token(contractAddress: Address, decimals: Int) -> Token {
        tokenFactory.token(contractAddress: contractAddress, decimals: decimals)
    }

    public func bestTradeExactIn(tokenIn: Token, tokenOut: Token, amountIn: Decimal) async throws -> Quoter.BestTrade {
        guard let amountIn = BigUInt(amountIn.hs.roundedString(decimal: tokenIn.decimals)), !amountIn.isZero else {
            throw TradeError.zeroAmount
        }

        return try await quoter.bestTradeExactIn(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
    }

    public func bestTradeExactOut(tokenIn: Token, tokenOut: Token, amountOut: Decimal) async throws -> Quoter.BestTrade {
        guard let amountOut = BigUInt(amountOut.hs.roundedString(decimal: tokenOut.decimals)), !amountOut.isZero else {
            throw TradeError.zeroAmount
        }

        return try await quoter.bestTradeExactOut(tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amountOut)
    }

    public func transactionData(bestTrade: Quoter.BestTrade, amountIn: BigUInt, amountOut: BigUInt, tradeOptions: TradeOptions) throws -> TransactionData {
        swapRouter.transactionData(swapPath: bestTrade.swapPath, amountIn: amountIn, amountOut: amountOut, tradeOptions: tradeOptions)
    }

}

extension KitV3 {

    public static func instance(evmKit: EvmKit.Kit) throws -> KitV3 {
        guard isSupported(chain: evmKit.chain) else {
            throw KitError.unsupportedChain
        }

        let tokenFactory = try TokenFactory(chain: evmKit.chain)
        let quoter = Quoter(evmKit: evmKit, tokenFactory: tokenFactory)
        let swapRouter = SwapRouter(evmKit: evmKit)
        let uniswapKit = KitV3(evmKit: evmKit, quoter: quoter, swapRouter: swapRouter, tokenFactory: tokenFactory)

        return uniswapKit
    }

    public static func addDecorators(to evmKit: EvmKit.Kit) {
        evmKit.add(methodDecorator: SwapMethodDecorator(contractMethodFactories: SwapContractMethodFactories.shared))
        evmKit.add(transactionDecorator: SwapTransactionDecorator())
    }

    public static func isSupported(chain: Chain) -> Bool {
        switch chain {
        case .ethereumGoerli, .ethereum, .polygon, .optimism, .arbitrumOne: return true
        default: return false
        }
    }

}

extension KitV3 {

    public enum FeeAmount: BigUInt, CaseIterable {
        case lowest = 100
        case low = 500
        case medium = 3000
        case high = 10000
    }

    public enum TradeError: Error {
        case zeroAmount
        case tradeNotFound
        case invalidTokensForSwap
    }

}

extension KitV3 {

    enum KitError: Error {
        case unsupportedChain
    }

}
