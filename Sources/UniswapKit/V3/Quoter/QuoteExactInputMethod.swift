import Foundation
import BigInt
import EvmKit

class QuoteExactInputMethod: ContractMethod {
    static let methodSignature = "quoteExactInput(bytes,uint256)"

    let swapPath: SwapPath
    let amountIn: BigUInt

    init(swapPath: SwapPath, amountIn: BigUInt) {
        self.swapPath = swapPath
        self.amountIn = amountIn

        super.init()
    }

    override var methodSignature: String { QuoteExactInputMethod.methodSignature }

    override var arguments: [Any] {
        [swapPath.abiEncodePacked, amountIn]
    }

}
