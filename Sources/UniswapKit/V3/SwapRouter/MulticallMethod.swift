import Foundation
import EvmKit

class MulticallMethod: ContractMethod {
    static let methodSignature = "multicall(bytes[])"

    let methods: [ContractMethod]

    init(methods: [ContractMethod]) {
        self.methods = methods
        super.init()
    }

    override var methodSignature: String { MulticallMethod.methodSignature }

    override var arguments: [Any] {
        [methods.map { $0.encodedABI() }]
    }

}
