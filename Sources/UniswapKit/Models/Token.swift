import EvmKit

public enum Token {
    case eth(wethAddress: Address)
    case erc20(address: Address, decimals: Int)

    public var address: Address {
        switch self {
        case let .eth(wethAddress): return wethAddress
        case let .erc20(address, _): return address
        }
    }

    var decimals: Int {
        switch self {
        case .eth: return 18
        case let .erc20(_, decimals): return decimals
        }
    }

    func sortsBefore(token: Token) -> Bool {
        address.raw.hs.hexString.lowercased() < token.address.raw.hs.hexString.lowercased()
    }

    public var isEther: Bool {
        switch self {
        case .eth: return true
        default: return false
        }
    }
}

extension Token: Equatable {
    public static func == (lhs: Token, rhs: Token) -> Bool {
        switch (lhs, rhs) {
        case let (.eth(lhsWethAddress), .eth(rhsWethAddress)): return lhsWethAddress == rhsWethAddress
        case let (.erc20(lhsAddress, lhsDecimals), .erc20(rhsAddress, rhsDecimals)): return lhsAddress == rhsAddress && lhsDecimals == rhsDecimals
        default: return false
        }
    }
}

extension Token: CustomStringConvertible {
    public var description: String {
        switch self {
        case .eth: return "[ETH]"
        case let .erc20(address, _): return "[ERC20: \(address)]"
        }
    }
}
