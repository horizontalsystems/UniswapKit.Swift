import BigInt
import Foundation
import HsExtensions

enum PriceImpactHelper {
    static func price(from sqrtPriceX96: BigUInt, shift: Int) -> Decimal? {
        let negative = shift < 0
        let decimalShift = BigUInt(10).power(abs(shift))

        let upper: BigUInt
        let downer: BigUInt
        if negative {
            upper = sqrtPriceX96 * sqrtPriceX96
            downer = BigUInt(2).power(192) * decimalShift
        } else {
            upper = sqrtPriceX96 * sqrtPriceX96 * decimalShift
            downer = BigUInt(2).power(192)
        }
        return Fraction(numerator: upper, denominator: downer).toDecimal(decimals: 18)
    }

    static func impact(price: Decimal, real: Decimal) -> Decimal? {
        guard price != 0 else { // if ideal price extremely small, it means that price impact ~100%
            return 99.9
        }
        return ((1 - real / price) * 100).hs.rounded(decimal: 2) / 100
    }

    static func price(in: BigUInt, out: BigUInt, shift: Int) -> Decimal? {
        let shift10 = BigInt(10).power(abs(shift)) * (shift >= 0 ? 1 : -1)
        let fraction = Fraction(numerator: out, denominator: `in`) * shift10
        return fraction.toDecimal(decimals: 18)
    }
}
