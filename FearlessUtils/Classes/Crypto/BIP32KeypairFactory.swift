import Foundation
import CommonCrypto
import IrohaCrypto
import BigInt

// swiftlint:disable line_length
public class ExtendedBIP32Keypair {
    let keypair: IRCryptoKeypairProtocol
    let chaincode: Data

    init(
        keypair: IRCryptoKeypairProtocol,
        chaincode: Data
    ){
        self.keypair = keypair
        self.chaincode = chaincode
    }
}

extension ExtendedBIP32Keypair: IRCryptoKeypairProtocol {
    public func publicKey() -> IRPublicKeyProtocol {
        keypair.publicKey()
    }

    public func privateKey() -> IRPrivateKeyProtocol {
        keypair.privateKey()
    }
}

public struct BIP32KeypairFactory: KeypairFactoryProtocol {
    let internalFactory = SECKeyFactory()
    let internalBIP32Factory = BIP32KeyFactory()

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
        let masterKeypair = try internalBIP32Factory.deriveFromSeed(seed)

        return try deriveChildKeypairFromParent(
            masterKeypair,
            chainIndexList: chaincodeList
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

    private func deriveChildKeypairFromParent(
        _ keypair: ExtendedBIP32Keypair,
        chainIndexList: [Chaincode]
    ) throws -> IRCryptoKeypairProtocol {

        let initExtendedKeypair = keypair
        let childExtendedKeypair = try chainIndexList.reduce(initExtendedKeypair) { (parentKeypair, chainIndex) in

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

            let hmacResult = try hmac512(hmacOriginalData, secretKeyData: parentKeypair.chaincode)

            // Split I into two 32-byte sequences, IL and IR.
            let childPrivateKeyData = try SECPrivateKey(rawData: hmacResult[...31])

            // The returned child key ki is parse256(IL) + kpar (mod n).
            let childKeyInt = (BigUInt(childPrivateKeyData.rawData()) +
                BigUInt(parentKeypair.privateKey().rawData())) %
                .secp256k1CurveOrder

            let numData  = childKeyInt.serialize()
            let childKey = try SECPrivateKey(rawData: numData)

            // The returned chain code ci is IR.
            let childChainCode = hmacResult[32...]

            // TODO:
            // In case parse256(IL) ≥ n or ki = 0, the resulting key is invalid,
            // and one should proceed with the next value for i. (Note: this has probability lower than 1 in 2127.)

            // The function N((k, c)) → (K, c) computes the extended public key corresponding to an extended private key
            // (the "neutered" version, as it removes the ability to sign transactions).

            // The returned key K is point(k).
            // The returned chain code c is just the passed chain code.
            let childKeypair = try internalFactory.derive(fromPrivateKey: childKey)

            return ExtendedBIP32Keypair(keypair: childKeypair, chaincode: childChainCode)
        }

        return childExtendedKeypair.keypair
    }

    public func deriveChildKeypairFromParent(_ keypair: IRCryptoKeypairProtocol,
                                             chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let childKeypair = try internalFactory.derive(fromPrivateKey: SECPrivateKey())
        return childKeypair
    }
}
// swiftlint:enable line_length

protocol BIP32KeyFactoryProtocol {
    func deriveFromSeed(_ seed: Data) throws -> ExtendedBIP32Keypair
}

public struct BIP32KeyFactory {
    private let initialSeed = "Bitcoin seed"
    let internalFactory = SECKeyFactory()

    private func generateHMAC512(
        from originalData: Data,
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
}

extension BIP32KeyFactory: BIP32KeyFactoryProtocol {
    func deriveFromSeed(_ seed: Data) throws -> ExtendedBIP32Keypair {
        let hmacResult = try generateHMAC512(
            from: seed,
            secretKeyData: Data(initialSeed.utf8)
        )

        let privateKey = try SECPrivateKey(rawData: hmacResult[...31])
        let chainCode = hmacResult[32...]

        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        return ExtendedBIP32Keypair(keypair: keypair, chaincode: chainCode)
    }
}
