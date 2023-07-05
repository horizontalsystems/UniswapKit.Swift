import Foundation
import EvmKit
import BigInt

public class KitV3 {
    private let evmKit: EvmKit.Kit
    private let quoter: QuoterV2
    private let swapRouter: SwapRouter
    private let tokenFactory: TokenFactory

    init(evmKit: EvmKit.Kit, quoter: QuoterV2, swapRouter: SwapRouter, tokenFactory: TokenFactory) {
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

    public func bestTradeExactIn(tokenIn: Token, tokenOut: Token, amountIn: Decimal, options: TradeOptions) async throws -> TradeDataV3 {
        guard let amountIn = BigUInt(amountIn.hs.roundedString(decimal: tokenIn.decimals)), !amountIn.isZero else {
            throw TradeError.zeroAmount
        }

        let trade = try await quoter.bestTradeExactIn(tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        return TradeDataV3(trade: trade, options: options)
    }

    public func bestTradeExactOut(tokenIn: Token, tokenOut: Token, amountOut: Decimal, options: TradeOptions) async throws -> TradeDataV3 {
        guard let amountOut = BigUInt(amountOut.hs.roundedString(decimal: tokenOut.decimals)), !amountOut.isZero else {
            throw TradeError.zeroAmount
        }

        let trade = try await quoter.bestTradeExactOut(tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amountOut)
        return TradeDataV3(trade: trade, options: options)
    }

    public func transactionData(bestTrade: TradeDataV3, tradeOptions: TradeOptions) throws -> TransactionData {
        swapRouter.transactionData(tradeData: bestTrade, tradeOptions: tradeOptions)
    }

}

extension KitV3 {

    public static func instance(evmKit: EvmKit.Kit, dexType: DexType) throws -> KitV3 {
        guard isSupported(chain: evmKit.chain) else {
            throw KitError.unsupportedChain
        }

        let tokenFactory = try TokenFactory(chain: evmKit.chain)
        let quoter = QuoterV2(evmKit: evmKit, tokenFactory: tokenFactory, dexType: dexType)
        let swapRouter = SwapRouter(evmKit: evmKit, dexType: dexType)
        let uniswapKit = KitV3(evmKit: evmKit, quoter: quoter, swapRouter: swapRouter, tokenFactory: tokenFactory)

        return uniswapKit
    }

    public static func addDecorators(to evmKit: EvmKit.Kit) throws {
        let tokenFactory = try TokenFactory(chain: evmKit.chain)
        evmKit.add(methodDecorator: SwapV3MethodDecorator(contractMethodFactories: SwapV3ContractMethodFactories.shared))
        evmKit.add(transactionDecorator: SwapV3TransactionDecorator(wethAddress: tokenFactory.etherToken.address))
    }

    public static func isSupported(chain: Chain) -> Bool {
        switch chain {
        case .ethereumGoerli, .ethereum, .polygon, .optimism, .arbitrumOne, .binanceSmartChain: return true
        default: return false
        }
    }

}

extension KitV3 {

    public enum FeeAmount: BigUInt, CaseIterable {
        case lowest = 100
        case low = 500
        case mediumPancakeSwap = 2500
        case mediumUniswap = 3000
        case high = 10000

        static func sorted(dexType: DexType) -> [FeeAmount] {
            [
                .lowest,
                .low,
                dexType.mediumFeeAmount,
                .high
            ]
        }
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
