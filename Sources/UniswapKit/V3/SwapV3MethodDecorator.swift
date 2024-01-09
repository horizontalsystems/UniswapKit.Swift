import EvmKit
import Foundation

class SwapV3MethodDecorator {
    private let contractMethodFactories: SwapV3ContractMethodFactories

    init(contractMethodFactories: SwapV3ContractMethodFactories) {
        self.contractMethodFactories = contractMethodFactories
    }
}

extension SwapV3MethodDecorator: IMethodDecorator {
    public func contractMethod(input: Data) -> ContractMethod? {
        contractMethodFactories.createMethod(input: input)
    }
}
