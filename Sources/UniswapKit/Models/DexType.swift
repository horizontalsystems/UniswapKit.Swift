import EvmKit

public enum DexType {
    case uniswap
    case pancakeSwap

    var mediumFeeAmount: KitV3.FeeAmount {
        switch self {
        case .uniswap: return .mediumUniswap
        case .pancakeSwap: return .mediumPancakeSwap
        }
    }

    func factoryAddress(chain: Chain) throws -> Address {
        switch self {
        case .uniswap:
            switch chain {
            case .ethereum, .polygon, .optimism, .arbitrumOne, .ethereumGoerli:
                return try Address(hex: "0x1F98431c8aD98523631AE4a59f267346ea31F984")
            case .binanceSmartChain:
                return try Address(hex: "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7")
            case .base:
                return try Address(hex: "0x33128a8fC17869897dcE68Ed026d694621f6FDfD")
            case .zkSync:
                return try Address(hex: "0x8FdA5a7a8dCA67BBcDd10F02Fa0649A937215422")
            case .robinhood:
                return try Address(hex: "0x1f7d7550b1b028f7571e69a784071f0205fd2efa")
            default:
                throw AddressError.invalidFactoryAddress
            }
        case .pancakeSwap:
            switch chain {
            case .binanceSmartChain, .ethereum, .base:
                return try Address(hex: "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865")
            case .zkSync:
                return try Address(hex: "0x1BB72E0CbbEA93c08f535fc7856E0338D7F7a8aB")
            default:
                throw AddressError.invalidFactoryAddress
            }
        }
    }

    func quoterAddress(chain: Chain) throws -> Address {
        switch self {
        case .uniswap:
            switch chain {
            case .ethereum, .polygon, .optimism, .arbitrumOne, .base, .binanceSmartChain:
                return try Address(hex: "0x88F1905197cCb1A94a1EA906F4e973bF6F2248dB")
            case .zkSync:
                return try Address(hex: "0x8Cb537fc92E26d8EBBb760E632c95484b6Ea3e28")
            case .robinhood:
                return try Address(hex: "0x33e885ed0ec9bf04ecfb19341582aadcb4c8a9e7")
            case .ethereumGoerli:
                return try Address(hex: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e")
            default: throw AddressError.invalidQuoterAddress
            }
        case .pancakeSwap:
            switch chain {
            case .binanceSmartChain, .base, .ethereum:
                return try Address(hex: "0xc9b8E9513D71c7Ce8B5482242545e18036Effff3")
            case .zkSync:
                return try Address(hex: "0x3d146FcE6c1006857750cBe8aF44f76a28041CCc")
            default:
                throw AddressError.invalidQuoterAddress
            }
        }
    }

    func routerAddress(chain: Chain) throws -> Address {
        switch self {
        case .uniswap:
            switch chain {
            case .ethereum, .polygon, .optimism, .arbitrumOne, .binanceSmartChain, .base:
                return try Address(hex: "0x8f934fD34A92C1df0DbA4bEfAe7d16CCF255FeBD")
            case .zkSync:
                return try Address(hex: "0x99c56385daBCE3E81d8499d0b8d0257aBC07E8A3")
            case .robinhood:
                return try Address(hex: "0xcaf681a66d020601342297493863e78c959e5cb2")
            case .ethereumGoerli:
                return try Address(hex: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45")
            default:
                throw AddressError.invalidRouterAddress
            }
        case .pancakeSwap:
            switch chain {
            case .base, .ethereum, .binanceSmartChain:
                return try Address(hex: "0x2a114a012A75A267b80a8a3c5FB26B32E86c32bA")
            case .zkSync:
                return try Address(hex: "0xf8b59f3c3Ab33200ec80a8A58b2aA5F5D2a8944C")
            default:
                throw AddressError.invalidRouterAddress
            }
      }
    }
}

extension DexType {
    enum AddressError: Error {
        case invalidRouterAddress
        case invalidQuoterAddress
        case invalidFactoryAddress
    }
}
