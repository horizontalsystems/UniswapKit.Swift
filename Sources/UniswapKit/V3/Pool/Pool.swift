import EvmKit
import Foundation

class Pool {
    private let evmKit: EvmKit.Kit
    private let token0: Address
    private let token1: Address
    private let fee: KitV3.FeeAmount

    let poolAddress: Address

    init(evmKit: EvmKit.Kit, token0: Address, token1: Address, fee: KitV3.FeeAmount, dexType: DexType) async throws {
        self.evmKit = evmKit
        self.token0 = token0
        self.token1 = token1
        self.fee = fee

        let method = GetPoolMethod(token0: token0, token1: token1, fee: fee.rawValue)

        let poolData = try await Self.call(
            evmKit: evmKit,
            address: dexType.factoryAddress(chain: evmKit.chain),
            data: method.encodedABI()
        )

        guard poolData.count >= 32 else {
            throw PoolError.cantCreateAddress
        }

        poolAddress = Address(raw: poolData[0 ..< 32])
    }

    private static func call(evmKit: EvmKit.Kit, address: Address, data: Data) async throws -> Data {
        do {
            let a = try await evmKit.fetchCall(contractAddress: address, data: data)
            return a
        } catch {
            throw error
        }
    }
}

extension Pool {
    public func slot0() async throws -> Slot0 {
        let method = Slot0Method()
        let data = try await Self.call(evmKit: evmKit, address: poolAddress, data: method.encodedABI())

        guard let slot0 = Slot0(data: data) else {
            throw PoolError.cantFetchSlot0
        }

        return slot0
    }

    public func token0() async throws -> String {
        let method = Token0Method()
        let data = try await Self.call(evmKit: evmKit, address: poolAddress, data: method.encodedABI())

        return Address(raw: data).hex
    }

    enum PoolError: Error {
        case cantCreateAddress
        case cantFetchSlot0
        case cantFetchToken0
    }
}
