import Foundation
import BigInt

public class TradeDataV3 {
    public let tradeType: TradeType
    let swapPath: SwapPath
    let _executionPrice: Price
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount

    public init(tradeType: TradeType, swapPath: SwapPath, amountIn: BigUInt, amountOut: BigUInt, tokenIn: Token, tokenOut: Token) {
        self.tradeType = tradeType
        self.swapPath = swapPath

        tokenAmountIn = TokenAmount(token: tokenIn, rawAmount: amountIn)
        tokenAmountOut = TokenAmount(token: tokenOut, rawAmount: amountOut)

        _executionPrice = Price(baseTokenAmount: tokenAmountIn, quoteTokenAmount: tokenAmountOut)
    }

}

extension TradeDataV3 {
    var isSingleSwap: Bool { swapPath.isSingle }
    var singleSwapFee: KitV3.FeeAmount { swapPath.firstFeeAmount }
}

extension TradeDataV3 {

    public var tradeAmountIn: Decimal? {
        tokenAmountIn.decimalAmount
    }

    public var tradeAmountOut: Decimal? {
        tokenAmountOut.decimalAmount
    }

    public var executionPrice: Decimal? {
        _executionPrice.decimalValue
    }

    public var executionPriceInverted: Decimal? {
        _executionPrice.invertedPrice.decimalValue
    }

    public var priceImpact: Decimal? {
        // todo:
        nil
    }

}
