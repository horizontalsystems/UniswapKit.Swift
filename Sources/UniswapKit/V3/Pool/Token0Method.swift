import Foundation
import EvmKit
import BigInt

class Token0Method: ContractMethod {
    static let methodSignature = "token0()"

    override var methodSignature: String { Token0Method.methodSignature }

    override var arguments: [Any] {
        []
    }

}
