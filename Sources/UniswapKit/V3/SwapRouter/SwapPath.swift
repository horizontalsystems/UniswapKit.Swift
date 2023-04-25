import Foundation
import EvmKit
import BigInt

public class SwapPath {
    public let tradeType: TradeType
    public let items: [SwapPathItem]

    public init(tradeType: TradeType, tokenIn: Token, tokenOut: Token, fee: KitV3.FeeAmount) {
        let token1 = tradeType == .exactIn ? tokenIn : tokenOut
        let token2 = tradeType == .exactOut ? tokenIn : tokenOut
        let fee = fee

        self.tradeType = tradeType
        items = [SwapPathItem(token1: token1, token2: token2, fee: fee)]
    }

    public init(tradeType: TradeType, items: [SwapPathItem]) throws {
        guard items.count >= 1 else {
            throw PathError.empty
        }
        self.tradeType = tradeType
        self.items = items
    }

    private func encodeUnit24(value: BigUInt) -> Data {
        let data =  value.serialize()
        let prePadding = Data(repeating: 0, count: max(0, 3 - data.count))
        return prePadding + data
    }

}

extension SwapPath {

    var isSingle: Bool { items.count == 1 }
    var tokenIn: Token { tradeType == .exactIn ? items.first!.token1 : items.last!.token2 }
    var tokenOut: Token { tradeType == .exactOut ? items.first!.token1 : items.last!.token2 }
    var firstFeeAmount: KitV3.FeeAmount { items.first!.fee }

    var abiEncodePacked: Data {
        var result = Data()
        guard let token1 = items.first?.token1 else {
            return result
        }

        result += token1.address.raw

        items.forEach { item in
            result += encodeUnit24(value: item.fee.rawValue) + item.token2.address.raw
        }

        return result
    }

}

extension SwapPath {

    enum PathError: Error {
        case empty
    }

}

public struct SwapPathItem {
    let token1: Token
    let token2: Token
    let fee: KitV3.FeeAmount

    public init(token1: Token, token2: Token, fee: KitV3.FeeAmount) {
        self.token1 = token1
        self.token2 = token2
        self.fee = fee
    }

}
