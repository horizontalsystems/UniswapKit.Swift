import Foundation
import EvmKit
import BigInt

class ExactInputMethod: ContractMethod {
    static let methodSignature = "exactInput((bytes,address,uint256,uint256,uint256))"

    let path: SwapPath
    let recipient: Address
    let deadline: BigUInt
    let amountIn: BigUInt
    let amountOutMinimum: BigUInt

    init(path: SwapPath, recipient: Address, deadline: BigUInt, amountIn: BigUInt, amountOutMinimum: BigUInt) {
        self.path = path
        self.recipient = recipient
        self.deadline = deadline
        self.amountIn = amountIn
        self.amountOutMinimum = amountOutMinimum

        super.init()
    }

    override var methodSignature: String { ExactInputMethod.methodSignature }

    override var arguments: [Any] {
        [ContractMethodHelper.DynamicStructParameter([path, recipient, deadline, amountIn, amountOutMinimum])]
    }

}
