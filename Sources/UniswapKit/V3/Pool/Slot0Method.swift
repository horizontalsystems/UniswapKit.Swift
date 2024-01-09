import BigInt
import EvmKit
import Foundation

class Slot0Method: ContractMethod {
    static let methodSignature = "slot0()"

    override var methodSignature: String { Slot0Method.methodSignature }

    override var arguments: [Any] {
        []
    }
}
