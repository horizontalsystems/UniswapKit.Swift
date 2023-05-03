import Foundation
import EvmKit
import BigInt

class SwapRouter {
    let routerAddress = try! Address(hex: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45") // for all supported  //0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45 // 0xE592427A0AEce92De3Edee1F18E0157C05861564
    private let evmKit: EvmKit.Kit

    init(evmKit: EvmKit.Kit) {
        self.evmKit = evmKit
    }

    private func buildMethodForExact(
            bestTrade: TradeDataV3,
            recipient: Address
    ) -> ContractMethod {
        if bestTrade.swapPath.isSingle {
            switch bestTrade.tradeType {
            case .exactIn:
                return ExactInputSingleMethod(
                    tokenIn: bestTrade.tokenAmountIn.token.address,
                        tokenOut: bestTrade.tokenAmountOut.token.address,
                        fee: bestTrade.swapPath.firstFeeAmount.rawValue,
                        recipient: recipient,
                        amountIn: bestTrade.tokenAmountIn.rawAmount,
                        amountOutMinimum: bestTrade.tokenAmountOut.rawAmount,
                        sqrtPriceLimitX96: 0
                )
            case .exactOut:
                return ExactOutputSingleMethod(
                        tokenIn: bestTrade.tokenAmountIn.token.address,
                        tokenOut: bestTrade.tokenAmountOut.token.address,
                        fee: bestTrade.swapPath.firstFeeAmount.rawValue,
                        recipient: recipient,
                        amountOut: bestTrade.tokenAmountOut.rawAmount,
                        amountInMaximum: bestTrade.tokenAmountIn.rawAmount,
                        sqrtPriceLimitX96: 0
                )
            }
        }

        switch bestTrade.tradeType {
        case .exactIn:
            return ExactInputMethod(
                    path: bestTrade.swapPath.abiEncodePacked,
                    recipient: recipient,
                    amountIn: bestTrade.tokenAmountIn.rawAmount,
                    amountOutMinimum: bestTrade.tokenAmountOut.rawAmount
            )
        case .exactOut:
            return ExactOutputMethod(
                    path: bestTrade.swapPath.abiEncodePacked,
                    recipient: recipient,
                    amountOut: bestTrade.tokenAmountOut.rawAmount,
                    amountInMaximum: bestTrade.tokenAmountIn.rawAmount
            )
        }
    }

}

extension SwapRouter {

    func transactionData(
            bestTrade: TradeDataV3,
            tradeOptions: TradeOptions
    ) -> TransactionData {
        let recipient = tradeOptions.recipient ?? evmKit.receiveAddress
//        let deadline = BigUInt(Date().timeIntervalSince1970 + tradeOptions.ttl)

        // if you try to swap erc20 -> ETH, recipient will be zeros.
        let swapRecipient = bestTrade.tokenAmountOut.token.isEther ? (try! Address(hex: "0x0000000000000000000000000000000000000000")) : recipient
        let ethValue = bestTrade.tokenAmountIn.token.isEther ? bestTrade.tokenAmountIn.rawAmount : 0

        let swapMethod = buildMethodForExact(
                bestTrade: bestTrade,
                recipient: swapRecipient
        )

        var methods = [ContractMethod]()
        methods.append(swapMethod)

        if bestTrade.tokenAmountIn.token.isEther && bestTrade.tradeType == .exactOut {
            methods.append(RefundEthMethod())
        }
        if bestTrade.tokenAmountOut.token.isEther {
            methods.append(UnwrapWeth9Method(amountMinimum: bestTrade.tokenAmountOut.rawAmount, recipient: recipient))
        }

        let resultMethod = (methods.count > 1) ? MulticallMethod(methods: methods) : swapMethod

        return TransactionData(to: routerAddress, value: ethValue, input: resultMethod.encodedABI())
    }

}
