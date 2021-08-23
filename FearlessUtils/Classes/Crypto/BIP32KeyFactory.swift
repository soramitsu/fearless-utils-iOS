import CommonCrypto
import IrohaCrypto
import BigInt

public enum BIP32KeyFactoryError: Error {
    case invalidChildKey
}

protocol BIP32KeyFactoryProtocol {
    func deriveFromSeed(_ seed: Data) throws -> BIP32ExtendedKeypair
    func createKeypairFrom(_ parentKeypair: BIP32ExtendedKeypair, chaincode: Chaincode) throws -> BIP32ExtendedKeypair
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
    func deriveFromSeed(_ seed: Data) throws -> BIP32ExtendedKeypair {
        let hmacResult = try generateHMAC512(
            from: seed,
            secretKeyData: Data(initialSeed.utf8)
        )

        let privateKey = try SECPrivateKey(rawData: hmacResult[...31])
        let chainCode = hmacResult[32...]

        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        return BIP32ExtendedKeypair(keypair: keypair, chaincode: chainCode)
    }

    func createKeypairFrom(
        _ parentKeypair: BIP32ExtendedKeypair,
        chaincode: Chaincode
    ) throws -> BIP32ExtendedKeypair {
        let sourceData: Data = try {
            switch chaincode.type {
            case .hard:
                let padding = try Data(hexString: "0x00")
                let privateKeyData = parentKeypair.privateKey().rawData()

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

        var privateKeyData  = privateKeyInt.serialize()

        if privateKeyData.count < 32 {
            var paddedPrivateKeyData = Data(repeating: 0, count: 32)
            paddedPrivateKeyData[(32 - privateKeyData.count)...] = privateKeyData
            privateKeyData = paddedPrivateKeyData
        }

        let privateKey = try SECPrivateKey(rawData: privateKeyData)

        let childChaincode = hmacResult[32...]
        let keypair = try internalFactory.derive(fromPrivateKey: privateKey)

        return BIP32ExtendedKeypair(keypair: keypair, chaincode: childChaincode)
    }
}
