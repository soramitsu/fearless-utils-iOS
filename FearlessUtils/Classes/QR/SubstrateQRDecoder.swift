import Foundation
import IrohaCrypto

open class SubstrateQRDecoder: SubstrateQRDecodable {
    public let chainType: ChainType
    public let separator: String
    public let prefix: String

    private lazy var addressFactory = SS58AddressFactory()

    public init(chainType: ChainType,
                prefix: String = SubstrateQR.prefix,
                separator: String = SubstrateQR.fieldsSeparator) {
        self.prefix = prefix
        self.chainType = chainType
        self.separator = separator
    }

    public func decode(data: Data) throws -> QRInfo {
        guard let fields = String(data: data, encoding: .utf8)?
            .components(separatedBy: separator) else {
            throw QRDecoderError.brokenFormat
        }

        guard fields.count >= 3, fields.count <= 4 else {
            throw QRDecoderError.unexpectedNumberOfFields
        }

        guard fields[0] == prefix else {
            throw QRDecoderError.undefinedPrefix
        }

        let address = fields[1]
        let accountId = try addressFactory.accountId(fromAddress: address, type: chainType)
        let publicKey = try Data(hexString: fields[2])

        guard publicKey.matchPublicKeyToAccountId(accountId) else {
            throw QRDecoderError.accountIdMismatch
        }

        let username = fields.count > 3 ? fields[3] : nil

        return SubstrateQRInfo(prefix: prefix,
                               address: address,
                               rawPublicKey: publicKey,
                               username: username)
    }
}
