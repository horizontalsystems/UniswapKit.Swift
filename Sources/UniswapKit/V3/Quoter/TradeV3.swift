import Foundation
import BigInt

public class TradeV3 {
    public let tradeType: TradeType
    let swapPath: SwapPath
    let _executionPrice: Price
    let slotPrices: [Decimal]
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount

    public init(tradeType: TradeType, swapPath: SwapPath, amountIn: BigUInt, amountOut: BigUInt, tokenIn: Token, tokenOut: Token, slotPrices: [Decimal]) {
        self.tradeType = tradeType
        self.swapPath = swapPath
        self.slotPrices = slotPrices

        tokenAmountIn = TokenAmount(token: tokenIn, rawAmount: amountIn)
        tokenAmountOut = TokenAmount(token: tokenOut, rawAmount: amountOut)

        _executionPrice = Price(baseTokenAmount: tokenAmountIn, quoteTokenAmount: tokenAmountOut)
    }

}

extension TradeV3 {
    var isSingleSwap: Bool { swapPath.isSingle }
    var singleSwapFee: KitV3.FeeAmount { swapPath.firstFeeAmount }
}

extension TradeV3 {

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
        let decimals = tokenAmountIn.token.decimals - tokenAmountOut.token.decimals
        let tradePrice = PriceImpactHelper.price(in: tokenAmountIn.rawAmount, out: tokenAmountOut.rawAmount, shift: decimals)

        var slotPrice: Decimal?
        if !slotPrices.isEmpty {
            var result: Decimal = 1
            slotPrices.forEach { decimal in
                result *= decimal
            }
            slotPrice = result
        } else {
            slotPrice = nil
        }

        guard let slotPrice,
              let tradePrice else {
            return nil
        }

        return PriceImpactHelper.impact(price: slotPrice, real: tradePrice)
    }

}
