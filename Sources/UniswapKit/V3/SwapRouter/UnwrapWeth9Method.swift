import Foundation
import EvmKit
import BigInt

class UnwrapWeth9Method: ContractMethod {
    static let methodSignature = "unwrapWETH9(uint256,address)"

    let amountMinimum: BigUInt
    let recipient: Address

    init(amountMinimum: BigUInt, recipient: Address) {
        self.amountMinimum = amountMinimum
        self.recipient = recipient

        super.init()
    }

    override var methodSignature: String { UnwrapWeth9Method.methodSignature }

    override var arguments: [Any] {
        [amountMinimum, recipient]
    }

}
