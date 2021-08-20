import Foundation
import IrohaCrypto

enum KeypairFactoryError: Error {
    case unsupportedChaincodeType
}

public protocol KeypairFactoryProtocol {
    func createKeypairFromSeed(_ seed: Data, chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol
}

public protocol DerivableKeypairFactoryProtocol: KeypairFactoryProtocol {
    func deriveChildKeypairFromParent(_ keypair: IRCryptoKeypairProtocol,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol
}

public protocol DerivableSeedFactoryProtocol: KeypairFactoryProtocol {
    func deriveChildSeedFromParent(_ seed: Data,
                                   chaincodeList: [Chaincode]) throws -> Data
}

public protocol DerivableChaincodeFactoryProtocol: KeypairFactoryProtocol {
    func deriveChildKeypairFromParent(_ keypair: IRCryptoKeypairProtocol,
                                      chaincodeList: [Chaincode],
                                      parChaincode: Data) throws -> IRCryptoKeypairProtocol
}
