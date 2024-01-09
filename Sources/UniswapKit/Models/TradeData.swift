import BigInt
import Foundation

public class TradeData {
    let trade: Trade
    public let options: TradeOptions

    init(trade: Trade, options: TradeOptions) {
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

public extension TradeData {
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

    var midPrice: Decimal? {
        trade.route.midPrice.decimalValue
    }

    var priceImpact: Decimal? {
        trade.priceImpact.toDecimal(decimals: 2)
    }

    var providerFee: Decimal? {
        guard let amountIn = type == .exactIn ? trade.tokenAmountIn.decimalAmount : tokenAmountInMax.decimalAmount else {
            return nil
        }

        return trade.liquidityProviderFee.toDecimal(decimals: trade.tokenAmountIn.token.decimals).map { $0 * amountIn }
    }

    var path: [Token] {
        trade.route.path
    }
}
