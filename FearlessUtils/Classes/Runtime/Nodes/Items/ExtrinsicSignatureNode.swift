import Foundation

public enum ExtrinsicSignatureNodeError: Error {
    case invalidParams
    case invalidRuntime
}

public class ExtrinsicSignatureNode: Node {
    public var typeName: String { GenericType.extrinsicSignature.name }
    public let runtimeMetadata: RuntimeMetadata

    public init(runtimeMetadata: RuntimeMetadata) {
        self.runtimeMetadata = runtimeMetadata
    }
    
    private var _addressType: KnownType?
    private func addressType() throws -> KnownType {
        if let addressType = _addressType {
            return addressType
        }
        
        let addressType: KnownType
        let resolver = runtimeMetadata.schemaResolver
        let hasAddressInRuntime = (try? resolver.resolveType(name: KnownType.address.rawValue)) != nil
        let hasAddressIdInRuntime = (try? resolver.resolveType(name: KnownType.addressId.rawValue)) != nil
        
        if hasAddressInRuntime {
            addressType = KnownType.address
        } else if hasAddressIdInRuntime {
            addressType = KnownType.addressId
        } else {
            throw ExtrinsicSignatureNodeError.invalidRuntime
        }
        
        _addressType = addressType
        return addressType
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        guard
            var address = params[ExtrinsicSignature.CodingKeys.address.rawValue],
            let signature = params[ExtrinsicSignature.CodingKeys.signature.rawValue],
            let extra = params[ExtrinsicSignature.CodingKeys.extra.rawValue] else {
            throw ExtrinsicSignatureNodeError.invalidParams
        }
        
        // Basically, all Substrate networks use "sp_runtime::multiaddress::MultiAddress" enum for destination
        // But some like Basilisk, use "sp_core::crypto::AccountId32" ([u8;32]) directly instead
        let addressType = try addressType()
        if addressType == KnownType.addressId {
            guard let id = address.arrayValue, id.count == 2, let idParam = id[1].arrayValue else {
                assertionFailure()
                throw GenericCallNodeError.unexpectedParams
            }
            
            address = .arrayValue(idParam)
        }

        try encoder.append(json: address, type: addressType.name)
        try encoder.append(json: signature, type: KnownType.signature.name)
        try encoder.append(json: extra, type: GenericType.extrinsicExtra.name)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let address = try decoder.read(type: KnownType.address.name)
        let signature = try decoder.read(type: KnownType.signature.name)
        let extra = try decoder.read(type: GenericType.extrinsicExtra.name)

        return .dictionaryValue([
            ExtrinsicSignature.CodingKeys.address.rawValue: address,
            ExtrinsicSignature.CodingKeys.signature.rawValue: signature,
            ExtrinsicSignature.CodingKeys.extra.rawValue: extra
        ])
    }
}
