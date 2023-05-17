import Foundation
import EvmKit
import BigInt

class SwapRouter {
    let routerAddress = try! Address(hex: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45")
    private let evmKit: EvmKit.Kit

    init(evmKit: EvmKit.Kit) {
        self.evmKit = evmKit
    }

    private func buildMethodForExact(
            trade: TradeV3,
            recipient: Address
    ) -> ContractMethod {
        if trade.swapPath.isSingle {
            switch trade.type {
            case .exactIn:
                return ExactInputSingleMethod(
                    tokenIn: trade.tokenAmountIn.token.address,
                        tokenOut: trade.tokenAmountOut.token.address,
                        fee: trade.swapPath.firstFeeAmount.rawValue,
                        recipient: recipient,
                        amountIn: trade.tokenAmountIn.rawAmount,
                        amountOutMinimum: trade.tokenAmountOut.rawAmount,
                        sqrtPriceLimitX96: 0
                )
            case .exactOut:
                return ExactOutputSingleMethod(
                        tokenIn: trade.tokenAmountIn.token.address,
                        tokenOut: trade.tokenAmountOut.token.address,
                        fee: trade.swapPath.firstFeeAmount.rawValue,
                        recipient: recipient,
                        amountOut: trade.tokenAmountOut.rawAmount,
                        amountInMaximum: trade.tokenAmountIn.rawAmount,
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
                    amountOutMinimum: trade.tokenAmountOut.rawAmount
            )
        case .exactOut:
            return ExactOutputMethod(
                    path: trade.swapPath.abiEncodePacked,
                    recipient: recipient,
                    amountOut: trade.tokenAmountOut.rawAmount,
                    amountInMaximum: trade.tokenAmountIn.rawAmount
            )
        }
    }

}

extension SwapRouter {

    func transactionData(
            tradeData: TradeDataV3,
            tradeOptions: TradeOptions
    ) -> TransactionData {
        let recipient = tradeOptions.recipient ?? evmKit.receiveAddress
//        let deadline = BigUInt(Date().timeIntervalSince1970 + tradeOptions.ttl)

        // if you try to swap erc20 -> ETH, recipient will be zeros.
        let swapRecipient = tradeData.trade.tokenAmountOut.token.isEther ? (try! Address(hex: "0x0000000000000000000000000000000000000002")) : recipient
        let ethValue = tradeData.trade.tokenAmountIn.token.isEther ? tradeData.trade.tokenAmountIn.rawAmount : 0

        let swapMethod = buildMethodForExact(
                trade: tradeData.trade,
                recipient: swapRecipient
        )

        var methods = [ContractMethod]()
        methods.append(swapMethod)

        if tradeData.trade.tokenAmountIn.token.isEther && tradeData.type == .exactOut {
            methods.append(RefundEthMethod())
        }
        if tradeData.trade.tokenAmountOut.token.isEther {
            methods.append(UnwrapWeth9Method(amountMinimum: tradeData.tokenAmountOutMin.rawAmount, recipient: recipient))
        }

        let resultMethod = (methods.count > 1) ? MulticallMethod(methods: methods) : swapMethod

        return TransactionData(to: routerAddress, value: ethValue, input: resultMethod.encodedABI())
    }

}
