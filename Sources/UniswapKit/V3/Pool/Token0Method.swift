import BigInt
import EvmKit
import Foundation

class Token0Method: ContractMethod {
    static let methodSignature = "token0()"

    override var methodSignature: String { Token0Method.methodSignature }

    override var arguments: [Any] {
        []
    }
}
