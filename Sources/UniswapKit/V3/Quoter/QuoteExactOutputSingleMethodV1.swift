import Foundation
import EvmKit
import BigInt

class QuoteExactOutputSingleMethodV1: ContractMethod {
    static let methodSignature = "quoteExactOutputSingle(address,address,uint24,uint256,uint160)"

    let tokenIn: Address
    let tokenOut: Address
    let fee: BigUInt
    let amountOut: BigUInt
    let sqrtPriceLimitX96: BigUInt

    init(tokenIn: Address, tokenOut: Address, fee: KitV3.FeeAmount, amountOut: BigUInt, sqrtPriceLimitX96: BigUInt) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.fee = fee.rawValue
        self.amountOut = amountOut
        self.sqrtPriceLimitX96 = sqrtPriceLimitX96

        super.init()
    }

    override var methodSignature: String { QuoteExactOutputSingleMethodV1.methodSignature }

    override var arguments: [Any] {
        [tokenIn, tokenOut, fee, amountOut, sqrtPriceLimitX96]
    }

}
