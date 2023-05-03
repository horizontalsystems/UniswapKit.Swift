import EvmKit

class SwapV3ContractMethodFactories: ContractMethodFactories {
    static let shared = SwapV3ContractMethodFactories()

    override init() {
        super.init()
        register(factories: [
            ExactInputSingleMethodFactory(),
            ExactOutputSingleMethodFactory(),
            ExactInputSingleMethodV1Factory(),
            ExactOutputSingleMethodV1Factory(),
            ExactInputMethodFactory(),
            ExactOutputMethodFactory(),
        ])
    }

}
