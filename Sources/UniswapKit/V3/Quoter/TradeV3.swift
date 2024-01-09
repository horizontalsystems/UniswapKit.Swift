import BigInt
import Foundation

public class TradeV3 {
    public let type: TradeType

    let swapPath: SwapPath
    let executionPrice: Price
    let slotPrices: [Decimal]
    let tokenAmountIn: TokenAmount
    let tokenAmountOut: TokenAmount

    public init(tradeType: TradeType, swapPath: SwapPath, amountIn: BigUInt, amountOut: BigUInt, tokenIn: Token, tokenOut: Token, slotPrices: [Decimal]) {
        type = tradeType
        self.swapPath = swapPath
        self.slotPrices = slotPrices

        tokenAmountIn = TokenAmount(token: tokenIn, rawAmount: amountIn)
        tokenAmountOut = TokenAmount(token: tokenOut, rawAmount: amountOut)

        executionPrice = Price(baseTokenAmount: tokenAmountIn, quoteTokenAmount: tokenAmountOut)
    }
}

public extension TradeV3 {
    var priceImpact: Decimal? {
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
              let tradePrice
        else {
            return nil
        }

        return PriceImpactHelper.impact(price: slotPrice, real: tradePrice)
    }
}
