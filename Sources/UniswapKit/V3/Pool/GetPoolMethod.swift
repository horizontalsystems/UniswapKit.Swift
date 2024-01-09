import BigInt
import EvmKit
import Foundation

class GetPoolMethod: ContractMethod {
    static let methodSignature = "getPool(address,address,uint24)"

    let token0: Address
    let token1: Address
    let fee: BigUInt

    init(token0: Address, token1: Address, fee: BigUInt) {
        self.token0 = token0
        self.token1 = token1
        self.fee = fee

        super.init()
    }

    override var methodSignature: String { GetPoolMethod.methodSignature }

    override var arguments: [Any] {
        [token0, token1, fee]
    }
}
