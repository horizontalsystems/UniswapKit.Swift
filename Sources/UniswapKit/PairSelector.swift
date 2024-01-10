import EvmKit

class PairSelector {
    private let tokenFactory: TokenFactory

    init(tokenFactory: TokenFactory) {
        self.tokenFactory = tokenFactory
    }

    func tokenPairs(chain: Chain, tokenA: Token, tokenB: Token) throws -> [(Token, Token)] {
        if tokenA.isEther || tokenB.isEther {
            return [(tokenA, tokenB)]
        } else {
            let etherToken = try tokenFactory.etherToken(chain: chain)

            return [(tokenA, tokenB), (tokenA, etherToken), (tokenB, etherToken)]
        }
    }
}
