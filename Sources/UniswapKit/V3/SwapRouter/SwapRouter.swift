import BigInt
import EvmKit
import Foundation

class SwapRouter {
    private let dexType: DexType

    init(dexType: DexType) {
        self.dexType = dexType
    }

    private func buildMethodForExact(
        tradeData: TradeDataV3,
        recipient: Address
    ) -> ContractMethod {
        let trade = tradeData.trade
        if trade.swapPath.isSingle {
            switch trade.type {
            case .exactIn:
                return ExactInputSingleMethod(
                    tokenIn: trade.tokenAmountIn.token.address,
                    tokenOut: trade.tokenAmountOut.token.address,
                    fee: trade.swapPath.firstFeeAmount.rawValue,
                    recipient: recipient,
                    amountIn: trade.tokenAmountIn.rawAmount,
                    amountOutMinimum: tradeData.tokenAmountOutMin.rawAmount,
                    sqrtPriceLimitX96: 0
                )
            case .exactOut:
                return ExactOutputSingleMethod(
                    tokenIn: trade.tokenAmountIn.token.address,
                    tokenOut: trade.tokenAmountOut.token.address,
                    fee: trade.swapPath.firstFeeAmount.rawValue,
                    recipient: recipient,
                    amountOut: trade.tokenAmountOut.rawAmount,
                    amountInMaximum: tradeData.tokenAmountInMax.rawAmount,
                    sqrtPriceLimitX96: 0
                )
            }
        }

        switch trade.type {
        case .exactIn:
            return ExactInputMethod(
                path: trade.swapPath.abiEncodePacked,
                recipient: recipient,
                amountIn: trade.tokenAmountIn.rawAmount,
                amountOutMinimum: tradeData.tokenAmountOutMin.rawAmount
            )
        case .exactOut:
            return ExactOutputMethod(
                path: trade.swapPath.abiEncodePacked,
                recipient: recipient,
                amountOut: trade.tokenAmountOut.rawAmount,
                amountInMaximum: tradeData.tokenAmountInMax.rawAmount
            )
        }
    }
}

extension SwapRouter {
    func transactionData(
        receiveAddress: Address,
        chain: Chain,
        tradeData: TradeDataV3,
        tradeOptions: TradeOptions
    ) -> TransactionData {
        let recipient = tradeOptions.recipient ?? receiveAddress
//        let deadline = BigUInt(Date().timeIntervalSince1970 + tradeOptions.ttl)

        // if you try to swap erc20 -> ETH, recipient will be zeros.
        let swapRecipient = tradeData.trade.tokenAmountOut.token.isEther ? (try! Address(hex: "0x0000000000000000000000000000000000000002")) : recipient
        let ethValue = tradeData.trade.tokenAmountIn.token.isEther ? tradeData.trade.tokenAmountIn.rawAmount : 0

        let swapMethod = buildMethodForExact(
            tradeData: tradeData,
            recipient: swapRecipient
        )

        var methods = [ContractMethod]()
        methods.append(swapMethod)

        if tradeData.trade.tokenAmountIn.token.isEther, tradeData.type == .exactOut {
            methods.append(RefundEthMethod())
        }
        if tradeData.trade.tokenAmountOut.token.isEther {
            methods.append(UnwrapWeth9Method(amountMinimum: tradeData.tokenAmountOutMin.rawAmount, recipient: recipient))
        }

        let resultMethod = (methods.count > 1) ? MulticallMethod(methods: methods) : swapMethod

        return TransactionData(to: dexType.routerAddress(chain: chain), value: ethValue, input: resultMethod.encodedABI())
    }
}
