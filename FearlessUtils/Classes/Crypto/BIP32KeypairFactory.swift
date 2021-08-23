import Foundation
import CommonCrypto
import IrohaCrypto
import BigInt

public class ExtendedBIP32Keypair {
    let keypair: IRCryptoKeypairProtocol
    let chaincode: Data

    init(
        keypair: IRCryptoKeypairProtocol,
        chaincode: Data
    ) {
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

public struct BIP32KeypairFactory {
    let internalBIP32Factory = BIP32KeyFactory()

    public init() {}

    private func deriveChildKeypairFromMaster(
        _ masterKeypair: ExtendedBIP32Keypair,
        chainIndexList: [Chaincode]
    ) throws -> IRCryptoKeypairProtocol {
        let childExtendedKeypair = try chainIndexList.reduce(masterKeypair) { (parentKeypair, chainIndex) in
            try internalBIP32Factory.createKeypairFrom(parentKeypair, chaincode: chainIndex)
        }

        return childExtendedKeypair.keypair
    }
}

extension BIP32KeypairFactory: KeypairFactoryProtocol {
    public func createKeypairFromSeed(_ seed: Data,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol {
        let masterKeypair = try internalBIP32Factory.deriveFromSeed(seed)

        return try deriveChildKeypairFromMaster(
            masterKeypair,
            chainIndexList: chaincodeList
        )
    }
}

public enum BIP32KeyFactoryError: Error {
    case invalidChildKey
}

protocol BIP32KeyFactoryProtocol {
    func deriveFromSeed(_ seed: Data) throws -> ExtendedBIP32Keypair
    func createKeypairFrom(_ parentKeypair: ExtendedBIP32Keypair, chaincode: Chaincode) throws -> ExtendedBIP32Keypair
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

    func createKeypairFrom(
        _ parentKeypair: ExtendedBIP32Keypair,
        chaincode: Chaincode
    ) throws -> ExtendedBIP32Keypair {
        let sourceData: Data = try {
            switch chaincode.type {
            case .hard:
                let padding = try Data(hexString: "0x00")
                let privateKeyData = BigUInt(parentKeypair.privateKey().rawData()).serialize()

                return padding + privateKeyData + chaincode.data

            case .soft:
                return parentKeypair.publicKey().rawData() + chaincode.data
            }
        }()

        let hmacResult = try generateHMAC512(
            from: sourceData,
            secretKeyData: parentKeypair.chaincode
        )

        let privateKeySourceData = try SECPrivateKey(rawData: hmacResult[...31])

        var privateKeyInt = BigUInt(privateKeySourceData.rawData())

        guard privateKeyInt < .secp256k1CurveOrder else {
            throw BIP32KeyFactoryError.invalidChildKey
        }

        privateKeyInt += BigUInt(parentKeypair.privateKey().rawData())
        privateKeyInt %= .secp256k1CurveOrder

        let privateKeyData  = privateKeyInt.serialize()
        let privateKey = try SECPrivateKey(rawData: privateKeyData)

        let childChaincode = hmacResult[32...]
        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        return ExtendedBIP32Keypair(keypair: keypair, chaincode: childChaincode)
    }
}
