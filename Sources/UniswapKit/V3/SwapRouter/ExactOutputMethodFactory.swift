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
              let amountOut = structArguments[2] as? BigUInt,
              let amountInMaximum = structArguments[3] as? BigUInt
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
