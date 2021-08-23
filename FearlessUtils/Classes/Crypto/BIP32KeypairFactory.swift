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
            chainIndexList: chaincodeList,
            parChaincode: masterChainCode
        )
    }

    /*
     The function CKDpriv((kpar, cpar), i) → (ki, ci) computes a child extended private key from the parent extended private key:

     Check whether i ≥ 231 (whether the child is a hardened key).
     If so (hardened child): let I = HMAC-SHA512(Key = cpar, Data = 0x00 || ser256(kpar) || ser32(i)). (Note: The 0x00 pads the private key to make it 33 bytes long.)
     If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i)).
     Split I into two 32-byte sequences, IL and IR.
     The returned child key ki is parse256(IL) + kpar (mod n).
     The returned chain code ci is IR.
     In case parse256(IL) ≥ n or ki = 0, the resulting key is invalid, and one should proceed with the next value for i. (Note: this has probability lower than 1 in 2127.)
     */

    public func deriveChildKeypairFromParent(
        _ keypair: IRCryptoKeypairProtocol,
        chainIndexList: [Chaincode],
        parChaincode: Data
    ) throws -> IRCryptoKeypairProtocol {

        let initKeypairAndChain = KeypairAndChain(keypair, parChaincode)
        let childKeypairAndChain = try chainIndexList.reduce(initKeypairAndChain) { (keypairAndChain, chainIndex) in

            let (parentKeypair, parentChaincode) = keypairAndChain

            let hmacOriginalData: Data = try {
                // Check whether i ≥ 231 (whether the child is a hardened key).
                switch chainIndex.type {
                // If so (hardened child): let I = HMAC-SHA512(Key = cpar, Data = 0x00 || ser256(kpar) || ser32(i)). (Note: The 0x00 pads the private key to make it 33 bytes long.)
                case .hard:
                    let padding = try Data(hexString: "0x00")
                    let privKeyData = BigUInt(parentKeypair.privateKey().rawData()).serialize()
                    return padding + privKeyData + chainIndex.data // chainIndex.data
                // If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i)).
                case .soft:
                    return parentKeypair.publicKey().rawData() + chainIndex.data // chainIndex.data
                }
            }()

            let hmacResult = try hmac512(hmacOriginalData, secretKeyData: parentChaincode)

            // Split I into two 32-byte sequences, IL and IR.
            let childPrivateKeyData = try SECPrivateKey(rawData: hmacResult[...31])

            // The returned child key ki is parse256(IL) + kpar (mod n).
            let childKeyInt = (BigUInt(childPrivateKeyData.rawData()) +
                BigUInt(parentKeypair.privateKey().rawData())) %
                .CurveOrder

            let numData  = childKeyInt.serialize()
            let childKey = try SECPrivateKey(rawData: numData)

            // The returned chain code ci is IR.
            let childChainCode = hmacResult[32...63]

            // TODO:
            // In case parse256(IL) ≥ n or ki = 0, the resulting key is invalid,
            // and one should proceed with the next value for i. (Note: this has probability lower than 1 in 2127.)

            // The function N((k, c)) → (K, c) computes the extended public key corresponding to an extended private key
            // (the "neutered" version, as it removes the ability to sign transactions).

            // The returned key K is point(k).
            // The returned chain code c is just the passed chain code.
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
