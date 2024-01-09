import BigInt
import Foundation

class QuoteExactSingleResponse {
    let amount: BigUInt
    let sqrtPriceX96After: BigUInt
    let initializedTicksCrossed: BigUInt
    let gasEstimate: BigUInt

    init?(data: Data) {
        guard data.count == 128 else {
            return nil
        }

        amount = BigUInt(data[0 ..< 32])
        sqrtPriceX96After = BigUInt(data[32 ..< 64])
        initializedTicksCrossed = BigUInt(data[64 ..< 96])
        gasEstimate = BigUInt(data[96 ..< 128])
    }
}
