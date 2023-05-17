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

    private func totalETHIncoming(userAddress: Address, transactions: [InternalTransaction]) -> BigUInt {
        var amountOut: BigUInt = 0
        transactions.forEach { transaction in
            if transaction.to == userAddress {
                amountOut += transaction.value
            }
        }

        return amountOut
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

        var tokenOutIsEther = false
        var recipientOverride: Address? = nil
        var swapMethod: ContractMethod? = contractMethod

        if let contractMethod = contractMethod as? MulticallMethod {
            let unwrapMethod = contractMethod.methods.compactMap { $0 as? UnwrapWeth9Method }.first
            swapMethod = contractMethod.methods.first(where: {
                $0 is ExactInputMethod ||
                $0 is ExactInputSingleMethod ||
                $0 is ExactOutputMethod ||
                $0 is ExactOutputSingleMethod
            })
            tokenOutIsEther = unwrapMethod != nil
            recipientOverride = unwrapMethod?.recipient
        }

        guard let swapMethod else {
            return nil
        }

        return decoration(
                from: from,
                to: to,
                value: value,
                contractMethod: swapMethod,
                internalTransactions: internalTransactions,
                eventInstances: eventInstances,
                tokenOutIsEther: tokenOutIsEther,
                recipientOverride: recipientOverride
        )
    }

    private func decoration(from: Address, to: Address, value: BigUInt, contractMethod: ContractMethod, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance], tokenOutIsEther: Bool, recipientOverride: Address?) -> TransactionDecoration? {
        let swapType = { (tokenIn: Address) in
            if tokenOutIsEther {
                 return SwapType.tokenToEth
            } else if value > 0, tokenIn == self.wethAddress {
                return SwapType.ethToToken
            } else {
                return SwapType.tokenToToken
            }
        }

        switch contractMethod {
        case let method as ExactInputSingleMethod:
            return exactIn(
                    from: from,
                    to: to,
                    value: value,
                    internalTransactions: internalTransactions,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountIn: method.amountIn,
                    amountOutMinimum: method.amountOutMinimum,
                    recipient: recipientOverride ?? method.recipient,
                    swapType: swapType(method.tokenIn))
        case let method as ExactInputSingleMethodV1:
            return exactIn(
                    from: from,
                    to: to,
                    value: value,
                    internalTransactions: internalTransactions,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountIn: method.amountIn,
                    amountOutMinimum: method.amountOutMinimum,
                    recipient: recipientOverride ?? method.recipient,
                    swapType: swapType(method.tokenIn),
                    deadline: method.deadline)
        case let method as ExactInputMethod:
            return exactIn(
                    from: from,
                    to: to,
                    value: value,
                    internalTransactions: internalTransactions,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountIn: method.amountIn,
                    amountOutMinimum: method.amountOutMinimum,
                    recipient: recipientOverride ?? method.recipient,
                    swapType: swapType(method.tokenIn))
        case let method as ExactOutputSingleMethod:
            return exactOut(
                    from: from,
                    to: to,
                    value: value,
                    internalTransactions: internalTransactions,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountOut: method.amountOut,
                    amountInMaximum: method.amountInMaximum,
                    recipient: recipientOverride ?? method.recipient,
                    swapType: swapType(method.tokenIn)
            )
        case let method as ExactOutputSingleMethodV1:
            return exactOut(
                    from: from,
                    to: to,
                    value: value,
                    internalTransactions: internalTransactions,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountOut: method.amountOut,
                    amountInMaximum: method.amountInMaximum,
                    recipient: recipientOverride ?? method.recipient,
                    swapType: swapType(method.tokenIn),
                    deadline: method.deadline
            )
        case let method as ExactOutputMethod:
            return exactOut(
                    from: from,
                    to: to,
                    value: value,
                    internalTransactions: internalTransactions,
                    eventInstances: eventInstances,
                    tokenIn: method.tokenIn,
                    tokenOut: method.tokenOut,
                    amountOut: method.amountOut,
                    amountInMaximum: method.amountInMaximum,
                    recipient: recipientOverride ?? method.recipient,
                    swapType: swapType(method.tokenIn)
            )
        default: return nil
        }
    }

    private func exactIn(from: Address, to: Address, value: BigUInt, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance], tokenIn: Address, tokenOut: Address, amountIn: BigUInt, amountOutMinimum: BigUInt, recipient: Address, swapType: SwapType, deadline: BigUInt? = nil) -> SwapDecoration {
        switch swapType {
        case .ethToToken:
            let amountOut = eventInstances.isEmpty ?
                    SwapDecoration.Amount.extremum(value: amountOutMinimum) :
                    SwapDecoration.Amount.exact(value:
                    totalTokenAmount(
                            userAddress: recipient,
                            tokenAddress: tokenOut,
                            eventInstances: eventInstances,
                            collectIncomingAmounts: false)
                    )
            return SwapDecoration(
                    contractAddress: to,
                    amountIn: .exact(value: value),
                    amountOut: amountOut,
                    tokenIn: .evmCoin,
                    tokenOut: eip20Token(address: tokenOut, eventInstances: eventInstances),
                    recipient: recipient == from ? nil : recipient,
                    deadline: deadline
            )
        case .tokenToEth:
            let amountOut = internalTransactions.isEmpty ?
                    SwapDecoration.Amount.extremum(value: amountOutMinimum) :
                    SwapDecoration.Amount.exact(value:
                    totalETHIncoming(
                            userAddress: recipient,
                            transactions: internalTransactions)
                    )
            return SwapDecoration(
                    contractAddress: to,
                    amountIn: .exact(value: amountIn),
                    amountOut: amountOut,
                    tokenIn: eip20Token(address: tokenIn, eventInstances: eventInstances),
                    tokenOut: .evmCoin,
                    recipient: recipient == from ? nil : recipient,
                    deadline: deadline
            )
        case .tokenToToken:
            let amountOut = eventInstances.isEmpty ?
                    SwapDecoration.Amount.extremum(value: amountOutMinimum) :
                    SwapDecoration.Amount.exact(value:
                    totalTokenAmount(
                            userAddress: recipient,
                            tokenAddress: tokenOut,
                            eventInstances: eventInstances,
                            collectIncomingAmounts: false)
                    )
            return SwapDecoration(
                    contractAddress: to,
                    amountIn: .exact(value: amountIn),
                    amountOut: amountOut,
                    tokenIn: eip20Token(address: tokenIn, eventInstances: eventInstances),
                    tokenOut: eip20Token(address: tokenOut, eventInstances: eventInstances),
                    recipient: recipient == from ? nil : recipient,
                    deadline: deadline
            )
        }
    }

    private func exactOut(from: Address, to: Address, value: BigUInt, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance], tokenIn: Address, tokenOut: Address, amountOut: BigUInt, amountInMaximum: BigUInt, recipient: Address, swapType: SwapType, deadline: BigUInt? = nil) -> SwapDecoration {
        switch swapType {
        case .ethToToken:
            let amountIn = internalTransactions.isEmpty ?
                    SwapDecoration.Amount.extremum(value: amountInMaximum) :
                    SwapDecoration.Amount.exact(value: totalETHIncoming(userAddress: recipient, transactions: internalTransactions))

            return SwapDecoration(
                    contractAddress: to,
                    amountIn: amountIn,
                    amountOut: .exact(value: amountOut),
                    tokenIn: SwapDecoration.Token.evmCoin,
                    tokenOut: eip20Token(address: tokenOut, eventInstances: eventInstances),
                    recipient: recipient == from ? nil : recipient,
                    deadline: deadline
            )
        case .tokenToEth, .tokenToToken:
            let amountIn = eventInstances.isEmpty ?
                    SwapDecoration.Amount.extremum(value: amountInMaximum) :
                    SwapDecoration.Amount.exact(value:
                    totalTokenAmount(
                            userAddress: recipient,
                            tokenAddress: tokenIn,
                            eventInstances: eventInstances,
                            collectIncomingAmounts: true)
                    )
            let tokenOut = swapType == .tokenToToken ? eip20Token(address: tokenOut, eventInstances: eventInstances) : .evmCoin
            return SwapDecoration(
                    contractAddress: to,
                    amountIn: amountIn,
                    amountOut: .exact(value: amountOut),
                    tokenIn: eip20Token(address: tokenIn, eventInstances: eventInstances),
                    tokenOut: tokenOut,
                    recipient: recipient == from ? nil : recipient,
                    deadline: deadline
            )
        }
    }

}

extension SwapV3TransactionDecorator {

    enum SwapType {
        case ethToToken, tokenToEth, tokenToToken
    }

}
