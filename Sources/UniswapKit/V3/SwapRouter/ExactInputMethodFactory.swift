import BigInt
import EvmKit
import Foundation

import BigInt
import EvmKit
import Foundation

class ExactInputMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: ExactInputMethod.methodSignature)

    func createMethod(inputArguments: Data) throws -> ContractMethod {
        let parsedArguments = ContractMethodHelper.decodeABI(inputArguments: inputArguments, argumentTypes: [
            ContractMethodHelper.DynamicStructParameter([
                Data.self,
                Address.self,
                BigUInt.self,
                BigUInt.self,
            ]),
        ])
        guard let structArguments = parsedArguments[0] as? [Any],
              let path = structArguments[0] as? Data,
              let recipient = structArguments[1] as? Address,
              let amountIn = structArguments[2] as? BigUInt,
              let amountOutMinimum = structArguments[3] as? BigUInt
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
