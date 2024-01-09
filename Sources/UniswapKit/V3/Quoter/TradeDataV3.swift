import BigInt
import Foundation

public class TradeDataV3 {
    let trade: TradeV3
    public let options: TradeOptions

    public init(trade: TradeV3, options: TradeOptions) {
        self.trade = trade
        self.options = options
    }

    var tokenAmountInMax: TokenAmount {
        let amountInMax = ((Fraction(numerator: 1) + options.slippageFraction) * Fraction(numerator: trade.tokenAmountIn.rawAmount)).quotient
        return TokenAmount(token: trade.tokenAmountIn.token, rawAmount: amountInMax)
    }

    var tokenAmountOutMin: TokenAmount {
        let amountOutMin = ((Fraction(numerator: 1) + options.slippageFraction).inverted * Fraction(numerator: trade.tokenAmountOut.rawAmount)).quotient
        return TokenAmount(token: trade.tokenAmountOut.token, rawAmount: amountOutMin)
    }
}

extension TradeDataV3 {
    var isSingleSwap: Bool { trade.swapPath.isSingle }
    var singleSwapFee: KitV3.FeeAmount { trade.swapPath.firstFeeAmount }
}

public extension TradeDataV3 {
    var type: TradeType {
        trade.type
    }

    var amountIn: Decimal? {
        trade.tokenAmountIn.decimalAmount
    }

    var amountOut: Decimal? {
        trade.tokenAmountOut.decimalAmount
    }

    var amountInMax: Decimal? {
        tokenAmountInMax.decimalAmount
    }

    var amountOutMin: Decimal? {
        tokenAmountOutMin.decimalAmount
    }

    var executionPrice: Decimal? {
        trade.executionPrice.decimalValue
    }

    var executionPriceInverted: Decimal? {
        trade.executionPrice.invertedPrice.decimalValue
    }

    var priceImpact: Decimal? {
        trade.priceImpact
    }
}
