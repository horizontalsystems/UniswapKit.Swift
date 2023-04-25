import Foundation
import BigInt
import EvmKit

class QuoteExactOutputMethod: ContractMethod {
    static let methodSignature = "quoteExactOutput(bytes,uint256)"

    let swapPath: SwapPath
    let amountOut: BigUInt

    init(swapPath: SwapPath, amountOut: BigUInt) {
        self.swapPath = swapPath
        self.amountOut = amountOut

        super.init()
    }

    override var methodSignature: String { QuoteExactOutputMethod.methodSignature }

    override var arguments: [Any] {
        [swapPath.abiEncodePacked, amountOut]
    }

}
