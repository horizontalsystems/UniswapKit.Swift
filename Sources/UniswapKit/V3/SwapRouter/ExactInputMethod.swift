import BigInt
import EvmKit
import Foundation

class ExactInputMethod: ContractMethod {
    static let methodSignature = "exactInput((bytes,address,uint256,uint256))"

    let path: Data
    let recipient: Address
    let amountIn: BigUInt
    let amountOutMinimum: BigUInt

    init(path: Data, recipient: Address, amountIn: BigUInt, amountOutMinimum: BigUInt) {
        self.path = path
        self.recipient = recipient
        self.amountIn = amountIn
        self.amountOutMinimum = amountOutMinimum

        super.init()
    }

    override var methodSignature: String { ExactInputMethod.methodSignature }

    override var arguments: [Any] {
        [ContractMethodHelper.DynamicStructParameter([path, recipient, amountIn, amountOutMinimum])]
    }
}

extension ExactInputMethod {
    var tokenIn: Address {
        Address(raw: path.prefix(20))
    }

    var tokenOut: Address {
        Address(raw: path.suffix(20))
    }
}
