import Foundation
import EvmKit
import BigInt

class ExactInputSingleMethodV1: ContractMethod {
    static let methodSignature = "exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))"

    let tokenIn: Address
    let tokenOut: Address
    let fee: BigUInt
    let recipient: Address
    let deadline: BigUInt
    let amountIn: BigUInt
    let amountOutMinimum: BigUInt
    let sqrtPriceLimitX96: BigUInt

    init(tokenIn: Address, tokenOut: Address, fee: BigUInt, recipient: Address, deadline: BigUInt, amountIn: BigUInt, amountOutMinimum: BigUInt, sqrtPriceLimitX96: BigUInt) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.fee = fee
        self.recipient = recipient
        self.deadline = deadline
        self.amountIn = amountIn
        self.amountOutMinimum = amountOutMinimum
        self.sqrtPriceLimitX96 = sqrtPriceLimitX96

        super.init()
    }

    override var methodSignature: String { ExactInputSingleMethodV1.methodSignature }

    override var arguments: [Any] {
        [tokenIn, tokenOut, fee, recipient, deadline, amountIn, amountOutMinimum, sqrtPriceLimitX96]
    }

}
