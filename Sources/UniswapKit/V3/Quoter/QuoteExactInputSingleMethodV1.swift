import Foundation
import EvmKit
import BigInt

class QuoteExactInputSingleMethodV1: ContractMethod {
    static let methodSignature = "quoteExactInputSingle(address,address,uint24,uint256,uint160)"

    let tokenIn: Address
    let tokenOut: Address
    let fee: BigUInt
    let amountIn: BigUInt
    let sqrtPriceLimitX96: BigUInt

    init(tokenIn: Address, tokenOut: Address, fee: KitV3.FeeAmount, amountIn: BigUInt, sqrtPriceLimitX96: BigUInt) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.fee = fee.rawValue
        self.amountIn = amountIn
        self.sqrtPriceLimitX96 = sqrtPriceLimitX96

        super.init()
    }

    override var methodSignature: String { QuoteExactInputSingleMethodV1.methodSignature }

    override var arguments: [Any] {
        [tokenIn, tokenOut, fee, amountIn, sqrtPriceLimitX96]
    }

}
