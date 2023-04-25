import EvmKit
import HsToolKit

class Configuration {
    static let shared = Configuration()

    let minLogLevel: Logger.Level = .error

    let chain: Chain = .ethereum
    let rpcSource: RpcSource = .ethereumInfuraHttp(projectId: "2a1306f1d12f4c109a4d4fb9be46b02e", projectSecret: "fc479a9290b64a84a15fa6544a130218")
    let transactionSource: TransactionSource = .ethereumEtherscan(apiKey: "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE")

    let defaultsWords = "apart approve black  comfort steel spin real renew tone primary key cherry"
    let defaultsWatchAddress = "0xDc3EAB13c26C0cA48843c16d1B27Ff8760515016"

    var erc20Tokens: [Erc20Token] {
        switch chain {
        case .ethereum: return [
            Erc20Token(name: "1INCH", code: "1INCH", contractAddress: try! Address(hex: "0x111111111117dC0aa78b770fA6A738034120C302"), decimals: 18),
            Erc20Token(name: "ArcBlock", code: "ABT", contractAddress: try! Address(hex: "0xB98d4C97425d9908E66E53A6fDf673ACcA0BE986"), decimals: 18),
            Erc20Token(name: "DAI", code: "DAI", contractAddress: try! Address(hex: "0x6b175474e89094c44da98b954eedeac495271d0f"), decimals: 18),
            Erc20Token(name: "SUSHI", code: "SUSHI", contractAddress: try! Address(hex: "0x6B3595068778DD592e39A122f4f5a5cF09C90fE2"), decimals: 18),
            Erc20Token(name: "USD Coin", code: "USDC", contractAddress: try! Address(hex: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"), decimals: 6),
            Erc20Token(name: "POP", code: "POP", contractAddress: try! Address(hex: "0xD0Cd466b34A24fcB2f87676278AF2005Ca8A78c4"), decimals: 18),
        ]
        case .binanceSmartChain: return [
            Erc20Token(name: "Beefy.Finance", code: "BIFI", contractAddress: try! Address(hex: "0xCa3F508B8e4Dd382eE878A314789373D80A5190A"), decimals: 18),
            Erc20Token(name: "PancakeSwap", code: "CAKE", contractAddress: try! Address(hex: "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82"), decimals: 18),
            Erc20Token(name: "BUSD", code: "BUSD", contractAddress: try! Address(hex: "0xe9e7cea3dedca5984780bafc599bd69add087d56"), decimals: 18),
        ]
        case .ethereumGoerli: return [
            Erc20Token(name: "WEENUS", code: "WEENUS", contractAddress: try! Address(hex: "0xaff4481d10270f50f203e0763e2597776068cbc5"), decimals: 18),
            Erc20Token(name: "USDT", code: "USDT", contractAddress: try! Address(hex: "0x183F3D42f1F78498f16bC6de7F5A6328fE39f25c"), decimals: 6)
        ]
        default: return []
        }
    }

}

struct Erc20Token {
    let name: String
    let code: String
    let contractAddress: Address
    let decimals: Int
}
