import Foundation
import EvmKit
import BigInt

class ExactOutputSingleMethod: ContractMethod {
    static let methodSignature = "exactOutputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))"

    let tokenIn: Address
    let tokenOut: Address
    let fee: BigUInt
    let recipient: Address
    let deadline: BigUInt
    let amountOut: BigUInt
    let amountInMaximum: BigUInt
    let sqrtPriceLimitX96: BigUInt

    init(tokenIn: Address, tokenOut: Address, fee: BigUInt, recipient: Address, deadline: BigUInt, amountOut: BigUInt, amountInMaximum: BigUInt, sqrtPriceLimitX96: BigUInt) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.fee = fee
        self.recipient = recipient
        self.deadline = deadline
        self.amountOut = amountOut
        self.amountInMaximum = amountInMaximum
        self.sqrtPriceLimitX96 = sqrtPriceLimitX96

        super.init()
    }

    override var methodSignature: String { ExactOutputSingleMethod.methodSignature }

    override var arguments: [Any] {
        [tokenIn, tokenOut, fee, recipient, deadline, amountOut, amountInMaximum, sqrtPriceLimitX96]
    }

}
