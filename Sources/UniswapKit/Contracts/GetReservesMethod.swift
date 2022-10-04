import EvmKit
import BigInt

class GetReservesMethod: ContractMethod {
    override var methodSignature: String { "getReserves()" }
    override var arguments: [Any] { [] }
}
