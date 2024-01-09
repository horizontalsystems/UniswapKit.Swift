import BigInt
import EvmKit
import Foundation

class ExactInputSingleMethod: ContractMethod {
    static let methodSignature = "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))"

    let tokenIn: Address
    let tokenOut: Address
    let fee: BigUInt
    let recipient: Address
    let amountIn: BigUInt
    let amountOutMinimum: BigUInt
    let sqrtPriceLimitX96: BigUInt

    init(tokenIn: Address, tokenOut: Address, fee: BigUInt, recipient: Address, amountIn: BigUInt, amountOutMinimum: BigUInt, sqrtPriceLimitX96: BigUInt) {
        self.tokenIn = tokenIn
        self.tokenOut = tokenOut
        self.fee = fee
        self.recipient = recipient
        self.amountIn = amountIn
        self.amountOutMinimum = amountOutMinimum
        self.sqrtPriceLimitX96 = sqrtPriceLimitX96

        super.init()
    }

    override var methodSignature: String { ExactInputSingleMethod.methodSignature }

    override var arguments: [Any] {
        [tokenIn, tokenOut, fee, recipient, amountIn, amountOutMinimum, sqrtPriceLimitX96]
    }
}
