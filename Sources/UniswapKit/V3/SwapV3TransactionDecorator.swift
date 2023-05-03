import EvmKit
import Eip20Kit
import BigInt

class SwapV3TransactionDecorator {
    private let wethAddress: Address

    init(wethAddress: Address) {
        self.wethAddress = wethAddress
    }

    private func totalTokenAmount(userAddress: Address, tokenAddress: Address, eventInstances: [ContractEventInstance], collectIncomingAmounts: Bool) -> BigUInt {
        var amountIn: BigUInt = 0
        var amountOut: BigUInt = 0

        for eventInstance in eventInstances {
            if eventInstance.contractAddress == tokenAddress, let transferEventInstance = eventInstance as? TransferEventInstance {
                if transferEventInstance.from == userAddress {
                    amountIn += transferEventInstance.value
                }

                if transferEventInstance.to == userAddress {
                    amountOut += transferEventInstance.value
                }
            }
        }

        return collectIncomingAmounts ? amountIn : amountOut
    }

    private func eip20Token(address: Address, eventInstances: [ContractEventInstance]) -> SwapDecoration.Token {
        .eip20Coin(
                address: address,
                tokenInfo: eventInstances.compactMap { $0 as? TransferEventInstance }.first { $0.contractAddress == address }?.tokenInfo
        )
    }

}

extension SwapV3TransactionDecorator: ITransactionDecorator {

    public func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration? {
        guard let from = from, let to = to, let value = value, let contractMethod = contractMethod else {
            return nil
        }

        switch contractMethod {
        case let method as ExactInputSingleMethod:
            return exactIn(
                    from: from,
                    to: to,
                    value: value,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountIn: method.amountIn,
                    amountOutMinimum: method.amountOutMinimum,
                    recipient: method.recipient)
        case let method as ExactInputSingleMethodV1:
            return exactIn(
                    from: from,
                    to: to,
                    value: value,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountIn: method.amountIn,
                    amountOutMinimum: method.amountOutMinimum,
                    recipient: method.recipient,
                    deadline: method.deadline)
        case let method as ExactInputMethod:
            return exactIn(
                    from: from,
                    to: to,
                    value: value,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountIn: method.amountIn,
                    amountOutMinimum: method.amountOutMinimum,
                    recipient: method.recipient)

        case let method as ExactOutputSingleMethod:
            return exactOut(
                    from: from,
                    to: to,
                    value: value,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountOut: method.amountOut,
                    amountInMaximum: method.amountInMaximum,
                    recipient: method.recipient
            )
        case let method as ExactOutputSingleMethodV1:
            return exactOut(
                    from: from,
                    to: to,
                    value: value,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountOut: method.amountOut,
                    amountInMaximum: method.amountInMaximum,
                    recipient: method.recipient,
                    deadline: method.deadline
            )
        case let method as ExactOutputMethod:
            return exactOut(
                    from: from,
                    to: to,
                    value: value,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountOut: method.amountOut,
                    amountInMaximum: method.amountInMaximum,
                    recipient: method.recipient
            )
        default: return nil
        }
    }

    private func exactIn(from: Address, to: Address, value: BigUInt, eventInstances: [ContractEventInstance], tokenIn: Address, tokenOut: Address, amountIn: BigUInt, amountOutMinimum: BigUInt, recipient: Address, deadline: BigUInt? = nil) -> SwapDecoration {
        let amountOut = eventInstances.isEmpty ?
                SwapDecoration.Amount.extremum(value: amountOutMinimum) :
                SwapDecoration.Amount.exact(value:
                totalTokenAmount(
                        userAddress: recipient,
                        tokenAddress: tokenOut,
                        eventInstances: eventInstances,
                        collectIncomingAmounts: false)
                )
        let swapDecorationAmountIn: SwapDecoration.Amount
        let swapDecorationTokenIn: SwapDecoration.Token

        let tokenInIsEther = value > 0 && tokenIn == wethAddress
        if tokenInIsEther {
            swapDecorationAmountIn = .exact(value: BigUInt(value))
            swapDecorationTokenIn = .evmCoin
        } else {
            swapDecorationAmountIn = .exact(value: amountIn)
            swapDecorationTokenIn = eip20Token(address: tokenIn, eventInstances: eventInstances)
        }

        return SwapDecoration(
                contractAddress: to,
                amountIn: swapDecorationAmountIn,
                amountOut: amountOut,
                tokenIn: swapDecorationTokenIn,
                tokenOut: eip20Token(address: tokenOut, eventInstances: eventInstances),
                recipient: recipient == from ? nil : recipient,
                deadline: deadline
        )

    }

    private func exactOut(from: Address, to: Address, value: BigUInt, eventInstances: [ContractEventInstance], tokenIn: Address, tokenOut: Address, amountOut: BigUInt, amountInMaximum: BigUInt, recipient: Address, deadline: BigUInt? = nil) -> SwapDecoration {
        let amountIn = eventInstances.isEmpty ?
                SwapDecoration.Amount.extremum(value: amountInMaximum) :
                SwapDecoration.Amount.exact(value:
                totalTokenAmount(
                        userAddress: recipient,
                        tokenAddress: tokenIn,
                        eventInstances: eventInstances,
                        collectIncomingAmounts: true)
                )

        let swapDecorationTokenIn: SwapDecoration.Token

        let tokenInIsEther = value > 0 && tokenIn == wethAddress
        if tokenInIsEther {
            swapDecorationTokenIn = .evmCoin
        } else {
            swapDecorationTokenIn = eip20Token(address: tokenOut, eventInstances: eventInstances)
        }

        return SwapDecoration(
                contractAddress: to,
                amountIn: amountIn,
                amountOut: .exact(value: amountOut),
                tokenIn: swapDecorationTokenIn,
                tokenOut: eip20Token(address: tokenOut, eventInstances: eventInstances),
                recipient: recipient == from ? nil : recipient,
                deadline: deadline
        )

    }

}
