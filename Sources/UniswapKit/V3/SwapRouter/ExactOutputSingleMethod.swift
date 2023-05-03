import Foundation
import EvmKit
import BigInt

class ExactOutputSingleMethod: ContractMethod {
    static let methodSignature = "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint160))"

    let tokenIn: Address
    let tokenOut: Address
    let fee: BigUInt
    let recipient: Address
    let amountOut: BigUInt
    let amountInMaximum: BigUInt
    let sqrtPriceLimitX96: BigUInt

    init(tokenIn: Address, tokenOut: Address, fee: BigUInt, recipient: Address, amountOut: BigUInt, amountInMaximum: BigUInt, sqrtPriceLimitX96: BigUInt) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.fee = fee
        self.recipient = recipient
        self.amountOut = amountOut
        self.amountInMaximum = amountInMaximum
        self.sqrtPriceLimitX96 = sqrtPriceLimitX96

        super.init()
    }

    override var methodSignature: String { ExactOutputSingleMethod.methodSignature }

    override var arguments: [Any] {
        [tokenIn, tokenOut, fee, recipient, amountOut, amountInMaximum, sqrtPriceLimitX96]
    }

}
