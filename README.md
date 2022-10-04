# UniswapKit.Swift

`UniswapKit.Swift` is an extension for `EvmKit.Swift` for supporting `Uniswap` native exchange

## Features

- Price Impact
- Deadline
- Recipient
- Fee on Transfer

## Usage

### Send Uniswap swap transaction

```swift
import EvmKit
import Eip20Kit
import UniswapKit

let uniswapKit = UniswapKit.Kit.instance(evmKit: evmKit)

let tokenIn = uniswapKit.etherToken
let tokenOut = uniswapKit.token(try! Address(hex: "0x..."), decimal: 18)
let amount: Decimal = 0.1

uniswapKit
        .swapDataSingle(tokenIn: tokenIn, tokenOut: tokenOut)
        .flatMap { swapData in
            let tradeData = try! uniswapKit.bestTradeExactIn(swapData: swapData, amountIn: amount)
            let transactionData = try! uniswapKit.transactionData(tradeData: tradeData)
            
            return evmKit.sendSingle(transactionData: transactionData, gasPrice: 50_000_000_000, gasLimit: 1_000_000_000_000)
        }
        .subscribe(onSuccess: { [weak self] _ in})
```

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/horizontalsystems/UniswapKit.Swift.git", .upToNextMajor(from: "1.0.0"))
]
```

## License

The `UniswapKit.Swift` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/ethereum-kit-ios/blob/master/LICENSE).

