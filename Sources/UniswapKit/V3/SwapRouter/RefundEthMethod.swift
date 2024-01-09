import EvmKit
import Foundation

class RefundEthMethod: ContractMethod {
    static let methodSignature = "refundETH()"

    override var methodSignature: String { RefundEthMethod.methodSignature }

    override var arguments: [Any] {
        []
    }
}
