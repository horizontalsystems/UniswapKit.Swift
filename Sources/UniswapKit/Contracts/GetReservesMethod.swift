import BigInt
import EvmKit

class GetReservesMethod: ContractMethod {
    override var methodSignature: String { "getReserves()" }
    override var arguments: [Any] { [] }
}
