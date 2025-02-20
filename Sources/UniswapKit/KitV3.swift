import BigInt
import EvmKit
import Foundation
import HsToolKit

public class KitV3 {
    private let dexType: DexType
    private let quoter: QuoterV2
    private let swapRouter: SwapRouter
    private let tokenFactory: TokenFactory

    init(dexType: DexType, quoter: QuoterV2, swapRouter: SwapRouter, tokenFactory: TokenFactory) {
        self.dexType = dexType
        self.quoter = quoter
        self.swapRouter = swapRouter
        self.tokenFactory = tokenFactory
    }
}

public extension KitV3 {
    func routerAddress(chain: Chain) -> Address {
        dexType.routerAddress(chain: chain)
    }

    func etherToken(chain: Chain) throws -> Token {
        try tokenFactory.etherToken(chain: chain)
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        tokenFactory.token(contractAddress: contractAddress, decimals: decimals)
    }

    func bestTradeExactIn(rpcSource: RpcSource, chain: Chain, tokenIn: Token, tokenOut: Token, amountIn: Decimal, options: TradeOptions) async throws -> TradeDataV3 {
        guard let amountIn = BigUInt(amountIn.hs.roundedString(decimal: tokenIn.decimals)), !amountIn.isZero else {
            throw TradeError.zeroAmount
        }

        let trade = try await quoter.bestTradeExactIn(rpcSource: rpcSource, chain: chain, tokenIn: tokenIn, tokenOut: tokenOut, amountIn: amountIn)
        return TradeDataV3(trade: trade, options: options)
    }

    func bestTradeExactOut(rpcSource: RpcSource, chain: Chain, tokenIn: Token, tokenOut: Token, amountOut: Decimal, options: TradeOptions) async throws -> TradeDataV3 {
        guard let amountOut = BigUInt(amountOut.hs.roundedString(decimal: tokenOut.decimals)), !amountOut.isZero else {
            throw TradeError.zeroAmount
        }

        let trade = try await quoter.bestTradeExactOut(rpcSource: rpcSource, chain: chain, tokenIn: tokenIn, tokenOut: tokenOut, amountOut: amountOut)
        return TradeDataV3(trade: trade, options: options)
    }

    func transactionData(receiveAddress: Address, chain: Chain, bestTrade: TradeDataV3, tradeOptions: TradeOptions) throws -> TransactionData {
        swapRouter.transactionData(receiveAddress: receiveAddress, chain: chain, tradeData: bestTrade, tradeOptions: tradeOptions)
    }
}

public extension KitV3 {
    static func instance(dexType: DexType) throws -> KitV3 {
        let networkManager = NetworkManager()
        let tokenFactory = TokenFactory()
        let quoter = QuoterV2(networkManager: networkManager, tokenFactory: tokenFactory, dexType: dexType)
        let swapRouter = SwapRouter(dexType: dexType)
        let uniswapKit = KitV3(dexType: dexType, quoter: quoter, swapRouter: swapRouter, tokenFactory: tokenFactory)

        return uniswapKit
    }

    static func addDecorators(to evmKit: EvmKit.Kit) throws {
        let tokenFactory = TokenFactory()
        evmKit.add(methodDecorator: SwapV3MethodDecorator(contractMethodFactories: SwapV3ContractMethodFactories.shared))
        try evmKit.add(transactionDecorator: SwapV3TransactionDecorator(wethAddress: tokenFactory.etherToken(chain: evmKit.chain).address))
    }

    static func isSupported(chain: Chain) -> Bool {
        switch chain {
        case .ethereumGoerli, .ethereum, .polygon, .optimism, .arbitrumOne, .binanceSmartChain, .base, .zkSync: return true
        default: return false
        }
    }
}

public extension KitV3 {
    enum FeeAmount: BigUInt, CaseIterable {
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
                .high,
            ]
        }
    }

    enum TradeError: Error {
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
