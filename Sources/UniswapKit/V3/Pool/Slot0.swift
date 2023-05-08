import Foundation
import BigInt

struct Slot0 {
    // the current price
        let sqrtPriceX96: BigUInt
    // the current tick
        let tick: BigUInt
    // the most-recently updated index of the observations array
        let observationIndex: BigUInt
    // the current maximum number of observations that are being stored
        let observationCardinality: BigUInt
    // the next maximum number of observations to store, triggered in observations.write
        let observationCardinalityNext: BigUInt
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
        let feeProtocol: BigUInt
    // whether the pool is locked
        let unlocked: Bool

    init?(data: Data) {
        guard data.count == 224 else {
            return nil
        }
        sqrtPriceX96 = BigUInt(data[0..<32])
        tick = BigUInt(data[32..<64])
        observationIndex = BigUInt(data[64..<96])
        observationCardinality = BigUInt(data[96..<128])
        observationCardinalityNext = BigUInt(data[128..<160])
        feeProtocol = BigUInt(data[160..<192])
        unlocked = data[223] != 0
    }

}
