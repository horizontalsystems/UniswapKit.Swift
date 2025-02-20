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

    func factoryAddress(chain: Chain) -> Address {
        switch self {
        case .uniswap:
            switch chain {
            case .binanceSmartChain: return try! Address(hex: "0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7")
            case .base: return try! Address(hex: "0x33128a8fC17869897dcE68Ed026d694621f6FDfD")
            case .zkSync: return try! Address(hex: "0x8FdA5a7a8dCA67BBcDd10F02Fa0649A937215422")
            default: return try! Address(hex: "0x1F98431c8aD98523631AE4a59f267346ea31F984")
            }
        case .pancakeSwap:
        switch chain {
            case .zkSync: return try! Address(hex: "0x1BB72E0CbbEA93c08f535fc7856E0338D7F7a8aB")
            default: return try! Address(hex: "0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865")
            }
        }
    }

    func quoterAddress(chain: Chain) -> Address {
        switch self {
        case .uniswap:
            switch chain {
            case .binanceSmartChain: return try! Address(hex: "0x78D78E420Da98ad378D7799bE8f4AF69033EB077")
            case .base: return try! Address(hex: "0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a")
            case .zkSync: return try! Address(hex: "0x8Cb537fc92E26d8EBBb760E632c95484b6Ea3e28")
            default: return try! Address(hex: "0x61fFE014bA17989E743c5F6cB21bF9697530B21e")
            }
        case .pancakeSwap:
            switch chain {
            case .zkSync: return try! Address(hex: "0x3d146FcE6c1006857750cBe8aF44f76a28041CCc")
            default: return try! Address(hex: "0xB048Bbc1Ee6b733FFfCFb9e9CeF7375518e25997")
            }
        }
    }

    func routerAddress(chain: Chain) -> Address {
        switch self {
        case .uniswap:
            switch chain {
            case .binanceSmartChain: return try! Address(hex: "0xB971eF87ede563556b2ED4b1C0b0019111Dd85d2")
            case .base: return try! Address(hex: "0x2626664c2603336E57B271c5C0b26F421741e481")
            case .zkSync: return try! Address(hex: "0x99c56385daBCE3E81d8499d0b8d0257aBC07E8A3")
            default: return try! Address(hex: "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45")
            }
        case .pancakeSwap:
            switch chain {
            case .base: return try! Address(hex: "0x678Aa4bF4E210cf2166753e054d5b7c31cc7fa86")
            case .zkSync: return try! Address(hex: "0xf8b59f3c3Ab33200ec80a8A58b2aA5F5D2a8944C")
            default: return try! Address(hex: "0x13f4EA83D0bd40E75C8222255bc855a974568Dd4")
            }
        }
    }
}
