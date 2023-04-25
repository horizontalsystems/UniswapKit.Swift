import Foundation
import EvmKit
import BigInt
import RxSwift

class SwapRouter {
    let routerAddress = try! Address(hex: "0xE592427A0AEce92De3Edee1F18E0157C05861564") // for all supported
    private let evmKit: EvmKit.Kit

    init(evmKit: EvmKit.Kit) {
        self.evmKit = evmKit
    }

    private func buildMethodForExact(
            swapPath: SwapPath,
            recipient: Address,
            deadline: BigUInt,
            amountIn: BigUInt,
            amountOut: BigUInt,
            sqrtPriceLimitX96: BigUInt
    ) -> ContractMethod {
        if swapPath.isSingle {
            switch swapPath.tradeType {
            case .exactIn:
                return ExactInputSingleMethod(
                        tokenIn: swapPath.tokenIn.address,
                        tokenOut: swapPath.tokenOut.address,
                        fee: swapPath.firstFeeAmount.rawValue,
                        recipient: recipient,
                        deadline: deadline,
                        amountIn: amountIn,
                        amountOutMinimum: amountOut,
                        sqrtPriceLimitX96: sqrtPriceLimitX96
                )
            case .exactOut:
                return ExactOutputSingleMethod(
                        tokenIn: swapPath.tokenIn.address,
                        tokenOut: swapPath.tokenOut.address,
                        fee: swapPath.firstFeeAmount.rawValue,
                        recipient: recipient,
                        deadline: deadline,
                        amountOut: amountOut,
                        amountInMaximum: amountIn,
                        sqrtPriceLimitX96: sqrtPriceLimitX96
                )
            }
        }

        switch swapPath.tradeType {
        case .exactIn:
            return ExactInputMethod(
                    path: swapPath,
                    recipient: recipient,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOut
            )
        case .exactOut:
            return ExactOutputMethod(
                    path: swapPath,
                    recipient: recipient,
                    deadline: deadline,
                    amountOut: amountOut,
                    amountInMaximum: amountIn
            )
        }
    }

}

extension SwapRouter {

    func transactionData(
            swapPath: SwapPath,
            amountIn: BigUInt,
            amountOut: BigUInt,
            tradeOptions: TradeOptions
    ) -> TransactionData {
        let recipient = tradeOptions.recipient ?? evmKit.receiveAddress
        let deadline = BigUInt(Date().timeIntervalSince1970 + tradeOptions.ttl)

        // if you try to swap erc20 -> ETH, recipient will be zeros.
        let swapRecipient = swapPath.tokenOut.isEther ? (try! Address(hex: "0x0000000000000000000000000000000000000000")) : recipient
        let ethValue = swapPath.tokenIn.isEther ? amountIn : 0

        let swapMethod =  buildMethodForExact(
                swapPath: swapPath,
                recipient: swapRecipient,
                deadline: deadline,
                amountIn: amountIn,
                amountOut: amountOut,
                sqrtPriceLimitX96: 0)

        var methods = [ContractMethod]()
        methods.append(swapMethod)

        if swapPath.tokenIn.isEther && swapPath.tradeType == .exactOut {
            methods.append(RefundEthMethod())
        }
        if swapPath.tokenOut.isEther {
            methods.append(UnwrapWeth9Method(amountMinimum: amountOut, recipient: recipient))
        }

        let resultMethod = (methods.count > 1) ? MulticallMethod(methods: methods) : swapMethod

        return TransactionData(to: routerAddress, value: ethValue, input: resultMethod.encodedABI())
    }

}
