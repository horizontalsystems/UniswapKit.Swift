import BigInt
import EvmKit
import Foundation

import BigInt
import EvmKit
import Foundation

class ExactOutputMethodFactory: IContractMethodFactory {
    let methodId: Data = ContractMethodHelper.methodId(signature: ExactOutputMethod.methodSignature)

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
              let amountOut = parsedArguments[2] as? BigUInt,
              let amountInMaximum = parsedArguments[3] as? BigUInt
        else {
            throw ContractMethodFactories.DecodeError.invalidABI
        }

        return ExactOutputMethod(
            path: path,
            recipient: recipient,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum
        )
    }
}
