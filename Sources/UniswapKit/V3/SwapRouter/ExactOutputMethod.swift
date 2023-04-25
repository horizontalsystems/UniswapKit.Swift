import Foundation
import EvmKit
import BigInt

class ExactOutputMethod: ContractMethod {
    static let methodSignature = "exactOutput((bytes,address,uint256,uint256,uint256))"

    let path: SwapPath
    let recipient: Address
    let deadline: BigUInt
    let amountOut: BigUInt
    let amountInMaximum: BigUInt

    init(path: SwapPath, recipient: Address, deadline: BigUInt, amountOut: BigUInt, amountInMaximum: BigUInt) {
        self.path = path
        self.recipient = recipient
        self.deadline = deadline
        self.amountOut = amountOut
        self.amountInMaximum = amountInMaximum

        super.init()
    }

    override var methodSignature: String { ExactOutputMethod.methodSignature }

    override var arguments: [Any] {
        [ContractMethodHelper.DynamicStructParameter([path, recipient, deadline, amountOut, amountInMaximum])]
    }

}
