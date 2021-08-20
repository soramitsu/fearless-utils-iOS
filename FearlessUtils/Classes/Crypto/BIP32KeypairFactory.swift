import Foundation
import CommonCrypto
import IrohaCrypto
import BigInt

// swiftlint:disable line_length
typealias KeypairAndChain = (keypair: IRCryptoKeypairProtocol, chaincode: Data)

extension BigUInt {
    static let CurveOrder: BigUInt = BigUInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
}

public struct BIP32KeypairFactory: DerivableKeypairFactoryProtocol, DerivableChaincodeFactoryProtocol {
    let internalFactory = SECKeyFactory()

    public init() {}

    private func hmac512(
        _ originalData: Data,
        secretKeyData: Data
    ) throws -> Data {
        let digestLength = Int(CC_SHA512_DIGEST_LENGTH)
        let algorithm = CCHmacAlgorithm(kCCHmacAlgSHA512)

        var buffer = [UInt8](repeating: 0, count: digestLength)

        originalData.withUnsafeBytes {
            let rawOriginalDataPtr = $0.baseAddress!

            secretKeyData.withUnsafeBytes {
                let rawSecretKeyPtr = $0.baseAddress!

                CCHmac(
                    algorithm,
                    rawSecretKeyPtr,
                    secretKeyData.count,
                    rawOriginalDataPtr,
                    originalData.count,
                    &buffer
                )
            }
        }

        return Data(bytes: buffer, count: digestLength)
    }

    ///       Create master keypair:
    ///        Generate a seed byte sequence S of a chosen length (between 128 and 512 bits; 256 bits is advised) from a (P)RNG.
    ///        Calculate I = HMAC-SHA512(Key = "Bitcoin seed", Data = S)
    ///        Split I into two 32-byte sequences, IL and IR.
    ///        Use parse256(IL) as master secret key, and IR as master chain code.
    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let hmacResult = try hmac512(seed, secretKeyData: Data("Bitcoin seed".utf8))

        let masterPrivateKey = try SECPrivateKey(rawData: hmacResult[...31])
        let masterChainCode = hmacResult[32...63]

        let masterKeypair = try internalFactory.derive(fromPrivateKey: masterPrivateKey)

        return try deriveChildKeypairFromParent(
            masterKeypair,
            chaincodeList: chaincodeList,
            parChaincode: masterChainCode
        )
    }

    public func deriveChildKeypairFromParent(
        _ keypair: IRCryptoKeypairProtocol,
        chaincodeList: [Chaincode],
        parChaincode: Data
    ) throws -> IRCryptoKeypairProtocol {

        let initKeyparAndChain = KeypairAndChain(keypair, parChaincode)
        let childKeypairAndChain = try chaincodeList.reduce(initKeyparAndChain) { (keyparAndChain, chaincode) in

            let (parKeypair, parChaincode) = keyparAndChain
            let hmacOriginalData: Data = {
                switch chaincode.type {
                case .soft:
                    return parKeypair.publicKey().rawData().dropFirst() + chaincode.data
                case .hard:
                    return parKeypair.privateKey().rawData() + chaincode.data
                }
            }()

            let hmacResult = try hmac512(hmacOriginalData, secretKeyData: parChaincode)

            let childPrivateKeyData = try SECPrivateKey(rawData: hmacResult[...31])
            let childChainCode = hmacResult[32...63]

            var childKeyNum = BigUInt(childPrivateKeyData.rawData())
            childKeyNum += BigUInt(parKeypair.privateKey().rawData())
            childKeyNum %= .CurveOrder

            let numData  = childKeyNum.serialize()
            let childKey = try SECPrivateKey(rawData: numData)

            let childKeypair = try internalFactory.derive(fromPrivateKey: childKey)

            return (childKeypair, childChainCode)
        }

        let (childKeypair, _) = childKeypairAndChain

        return IRCryptoKeypair(publicKey: childKeypair.publicKey(),
                               privateKey: childKeypair.privateKey())
    }

    public func deriveChildKeypairFromParent(_ keypair: IRCryptoKeypairProtocol,
                                             chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let childKeypair = try internalFactory.derive(fromPrivateKey: SECPrivateKey())
        return childKeypair
    }
}
// swiftlint:enable line_length
