import Foundation
import BigInt

public final class DynamicScaleEncoder {
    private var encoder: ScaleEncoder = ScaleEncoder()

    private var modifiers: [ScaleCodingModifier] = []

    public let registry: TypeRegistryCatalogProtocol
    public let version: UInt64

    public init(registry: TypeRegistryCatalogProtocol, version: UInt64) {
        self.registry = registry
        self.version = version
    }

    private func handleCommonOption(for json: JSON) {
        if case .null = json {
            encoder.appendRaw(data: Data([0]))
        } else {
            encoder.appendRaw(data: Data([1]))
        }
    }

    private func handleBoolOption(for value: Bool?) throws {
        try ScaleBoolOption(value: value).encode(scaleEncoder: encoder)
    }

    private func encodeCompact(value: JSON) throws {
        guard let str = value.stringValue, let bigInt = BigUInt(str) else {
            throw DynamicScaleEncoderError.expectedStringForCompact(json: value)
        }

        try bigInt.encode(scaleEncoder: encoder)
    }
    
    // MARK: - Signed
    
    private func encodeFixedInt(value: JSON, byteLength: Int) throws {
        guard let str = value.stringValue, let intValue = BigInt(str) else {
            throw DynamicScaleEncoderError.expectedStringForInt(json: value)
        }

        var encodedData: [UInt8] = intValue.serialize().reversed()

        while encodedData.count < byteLength {
            encodedData.append(0)
        }

        encoder.appendRaw(data: Data(encodedData))
    }
    
    private func appendFixedSigned(json: JSON, byteLength: Int) throws {
        if modifiers.last == .compact {
            modifiers.removeLast()
            assertionFailure()
            throw DynamicScaleCoderError.notImplemented
        } else {
            try encodeFixedUInt(value: json, byteLength: byteLength)
        }
    }
    
    // MARK: - Unsigned

    private func encodeFixedUInt(value: JSON, byteLength: Int) throws {
        guard let str = value.stringValue, let intValue = BigUInt(str) else {
            throw DynamicScaleEncoderError.expectedStringForInt(json: value)
        }

        var encodedData: [UInt8] = intValue.serialize().reversed()

        while encodedData.count < byteLength {
            encodedData.append(0)
        }

        encoder.appendRaw(data: Data(encodedData))
    }

    private func appendFixedUnsigned(json: JSON, byteLength: Int) throws {
        if modifiers.last == .compact {
            modifiers.removeLast()

           try encodeCompact(value: json)
        } else {
            try encodeFixedUInt(value: json, byteLength: byteLength)
        }
    }
}

extension DynamicScaleEncoder: DynamicScaleEncoding {
    public func append(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolvedType(name: type)
        }

        Log.write("DynamicScale", message: "append of type \(type) json: \(json)")
        try node.accept(encoder: self, value: json)
    }

    public func appendOption(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolvedType(name: type)
        }

        if node is BoolNode {
            try handleBoolOption(for: json.boolValue)
            Log.write("DynamicScale", message: "append option bool: \(json.boolValue)")
        } else {
            handleCommonOption(for: json)

            Log.write("DynamicScale", message: "append option of type \(type) json: \(json)")
            if !json.isNull {
                try node.accept(encoder: self, value: json)
            }
        }
    }

    public func appendVector(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolvedType(name: type)
        }

        guard let items = json.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: json)
        }

        Log.write("DynamicScale", message: "append vector of type \(type): \(items)")
        try BigUInt(items.count).encode(scaleEncoder: encoder)

        for item in items {
            try node.accept(encoder: self, value: item)
        }
    }

    public func appendCompact(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolvedType(name: type)
        }

        modifiers.append(.compact)

        Log.write("DynamicScale", message: "append compact of type \(type) json: \(json)")
        try node.accept(encoder: self, value: json)
    }

    public func appendFixedArray(json: JSON, type: String) throws {
        guard let node = registry.node(for: type, version: version) else {
            throw DynamicScaleCoderError.unresolvedType(name: type)
        }

        guard let items = json.arrayValue else {
            throw DynamicScaleEncoderError.arrayExpected(json: json)
        }

        Log.write("DynamicScale", message: "append fixed array of type \(type): \(items)")
        for item in items {
            try node.accept(encoder: self, value: item)
        }
    }

    public func appendBytes(json: JSON) throws {
        guard let hex = json.stringValue, let data = try? Data(hexString: hex) else {
            throw DynamicScaleEncoderError.hexExpected(json: json)
        }

        Log.write("DynamicScale", message: "append bytes: \(hex)")
        encoder.appendRaw(data: data)
    }

    public func appendString(json: JSON) throws {
        guard let str = json.stringValue else {
            throw DynamicScaleEncoderError.hexExpected(json: json)
        }

        Log.write("DynamicScale", message: "append string: \(str)")
        try str.encode(scaleEncoder: encoder)
    }

    public func appendU8(json: JSON) throws {
        Log.write("DynamicScale", message: "append u8: \(json)")
        try appendFixedUnsigned(json: json, byteLength: 1)
    }

    public func appendU16(json: JSON) throws {
        Log.write("DynamicScale", message: "append u16: \(json)")
        try appendFixedUnsigned(json: json, byteLength: 2)
    }

    public func appendU32(json: JSON) throws {
        Log.write("DynamicScale", message: "append u32: \(json)")
        try appendFixedUnsigned(json: json, byteLength: 4)
    }

    public func appendU64(json: JSON) throws {
        Log.write("DynamicScale", message: "append u64: \(json)")
        try appendFixedUnsigned(json: json, byteLength: 8)
    }

    public func appendU128(json: JSON) throws {
        Log.write("DynamicScale", message: "append u128: \(json)")
        try appendFixedUnsigned(json: json, byteLength: 16)
    }

    public func appendU256(json: JSON) throws {
        Log.write("DynamicScale", message: "append u256: \(json)")
        try appendFixedUnsigned(json: json, byteLength: 32)
    }
    
    public func appendI8(json: JSON) throws {
        Log.write("DynamicScale", message: "append i8: \(json)")
        try appendFixedSigned(json: json, byteLength: 1)
    }

    public func appendI16(json: JSON) throws {
        Log.write("DynamicScale", message: "append i16: \(json)")
        try appendFixedSigned(json: json, byteLength: 2)
    }

    public func appendI32(json: JSON) throws {
        Log.write("DynamicScale", message: "append i32: \(json)")
        try appendFixedSigned(json: json, byteLength: 4)
    }

    public func appendI64(json: JSON) throws {
        Log.write("DynamicScale", message: "append i64: \(json)")
        try appendFixedSigned(json: json, byteLength: 8)
    }

    public func appendI128(json: JSON) throws {
        Log.write("DynamicScale", message: "append i128: \(json)")
        try appendFixedSigned(json: json, byteLength: 16)
    }

    public func appendI256(json: JSON) throws {
        Log.write("DynamicScale", message: "append i256: \(json)")
        try appendFixedSigned(json: json, byteLength: 32)
    }

    public func appendBool(json: JSON) throws {
        guard let value = json.boolValue else {
            throw DynamicScaleEncoderError.expectedStringForBool(json: json)
        }
        
        Log.write("DynamicScale", message: "append bool: \(value)")
        try value.encode(scaleEncoder: encoder)
    }

    public func append<T: ScaleCodable>(encodable: T) throws {
        Log.write("DynamicScale", message: "append generic: \(encodable)")
        try encodable.encode(scaleEncoder: encoder)
    }

    public func newEncoder() -> DynamicScaleEncoding {
        DynamicScaleEncoder(registry: registry, version: version)
    }

    public func encode() throws -> Data {
        encoder.encode()
    }
}
