import EvmKit

class TokenFactory {
    func etherToken(chain: Chain) throws -> Token {
        try .eth(wethAddress: Self.wethAddress(chain: chain))
    }

    func token(contractAddress: Address, decimals: Int) -> Token {
        .erc20(address: contractAddress, decimals: decimals)
    }
}

extension TokenFactory {
    private static func wethAddress(chain: Chain) throws -> Address {
        let wethAddressHex: String

        switch chain {
        case .ethereum: wethAddressHex = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        case .optimism: wethAddressHex = "0x4200000000000000000000000000000000000006"
        case .binanceSmartChain: wethAddressHex = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c"
        case .polygon: wethAddressHex = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
        case .avalanche: wethAddressHex = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"
        case .ethereumRopsten, .ethereumRinkeby: wethAddressHex = "0xc778417E063141139Fce010982780140Aa0cD5Ab"
        case .ethereumKovan: wethAddressHex = "0xd0A1E359811322d97991E03f863a0C30C2cF029C"
        case .ethereumGoerli: wethAddressHex = "0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"
        case .arbitrumOne: wethAddressHex = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"
        case .base: wethAddressHex = "0x4200000000000000000000000000000000000006"
        case .zkSync: wethAddressHex = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91"
        default: throw UnsupportedChainError.noWethAddress
        }

        return try Address(hex: wethAddressHex)
    }

    enum UnsupportedChainError: Error {
        case noWethAddress
    }
}
