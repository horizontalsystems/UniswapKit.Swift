import Foundation
import EvmKit
import BigInt

class ExactOutputMethod: ContractMethod {
    static let methodSignature = "exactOutput((bytes,address,uint256,uint256))"

    let path: Data
    let recipient: Address
    let amountOut: BigUInt
    let amountInMaximum: BigUInt

    init(path: Data, recipient: Address, amountOut: BigUInt, amountInMaximum: BigUInt) {
        self.path = path
        self.recipient = recipient
        self.amountOut = amountOut
        self.amountInMaximum = amountInMaximum

        super.init()
    }

    override var methodSignature: String { ExactOutputMethod.methodSignature }

    override var arguments: [Any] {
        [ContractMethodHelper.DynamicStructParameter([path, recipient, amountOut, amountInMaximum])]
    }

}

extension ExactOutputMethod {

    var tokenIn: Address {
        Address(raw: path.suffix(20))
    }

    var tokenOut: Address {
        Address(raw: path.prefix(20))
    }

}
