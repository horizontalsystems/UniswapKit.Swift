import EvmKit
import Foundation

class SwapMethodDecorator {
    private let contractMethodFactories: SwapContractMethodFactories

    init(contractMethodFactories: SwapContractMethodFactories) {
        self.contractMethodFactories = contractMethodFactories
    }
}

extension SwapMethodDecorator: IMethodDecorator {
    public func contractMethod(input: Data) -> ContractMethod? {
        contractMethodFactories.createMethod(input: input)
    }
}
