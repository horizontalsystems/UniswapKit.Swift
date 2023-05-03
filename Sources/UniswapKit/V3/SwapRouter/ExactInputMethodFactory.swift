import Foundation
import EvmKit
import BigInt

import Foundation
import EvmKit
import BigInt

class ExactInputMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: ExactInputMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: [
            Data.self,
            Address.self,
            BigUInt.self,
            BigUInt.self,
            BigUInt.self,
        ])
        guard let path = parsedArguments[0] as? Data,
              let recipient = parsedArguments[1] as? Address,
              let amountIn = parsedArguments[2] as? BigUInt,
              let amountOutMinimum = parsedArguments[3] as? BigUInt
        else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        return ExactInputMethod(
                path: path,
                recipient: recipient,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum
        )
    }

}
