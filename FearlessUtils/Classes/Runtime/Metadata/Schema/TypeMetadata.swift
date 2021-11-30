import Foundation
import BigInt

// MARK: - TypeMetadata

public struct TypeMetadata {
    public let path: [String]
    public let params: [Param]
    public let def: Def
    public let docs: [String]
}

// MARK: TypeMetadata.Param

extension TypeMetadata {
    public struct Param: ScaleCodable {
        public let name: String
        public let type: BigUInt?

        public func encode(scaleEncoder: ScaleEncoding) throws {
            try name.encode(scaleEncoder: scaleEncoder)
            try ScaleOption(value: type).encode(scaleEncoder: scaleEncoder)
        }

        public init(scaleDecoder: ScaleDecoding) throws {
            self.name = try String(scaleDecoder: scaleDecoder)
            self.type = try ScaleOption(scaleDecoder: scaleDecoder).value
        }
    }
}

extension TypeMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try path.encode(scaleEncoder: scaleEncoder)
        try params.encode(scaleEncoder: scaleEncoder)
        try def.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.path = try [String](scaleDecoder: scaleDecoder)
        self.params = try [Param](scaleDecoder: scaleDecoder)
        self.def = try Def(scaleDecoder: scaleDecoder)
        self.docs = try [String](scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def

extension TypeMetadata {
    public enum Def {
        case composite(Composite)
        case variant(Variant)
        case sequence(Sequence)
        case array(Array)
        case tuple([BigUInt])
        case `enum`(Enum)
        case compact(Compact)
        case bitSequence(BitSequence)
    }
}

extension TypeMetadata.Def: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        let index: UInt8
        let encoding: ScaleCodable
        switch self {
        case let .composite(value):
            index = 0
            encoding = value
        case let .variant(value):
            index = 1
            encoding = value
        case let .sequence(value):
            index = 2
            encoding = value
        case let .array(value):
            index = 3
            encoding = value
        case let .tuple(value):
            index = 4
            encoding = value
        case let .enum(value):
            index = 5
            encoding = value
        case let .compact(value):
            index = 6
            encoding = value
        case let .bitSequence(value):
            index = 7
            encoding = value
        }

        try index.encode(scaleEncoder: scaleEncoder)
        try encoding.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let index = try UInt8(scaleDecoder: scaleDecoder)
        switch index {
        case 0: self = .composite(try Composite(scaleDecoder: scaleDecoder))
        case 1: self = .variant(try Variant(scaleDecoder: scaleDecoder))
        case 2: self = .sequence(try Sequence(scaleDecoder: scaleDecoder))
        case 3: self = .array(try Array(scaleDecoder: scaleDecoder))
        case 4: self = .tuple(try [BigUInt](scaleDecoder: scaleDecoder))
        case 5: self = .enum(try Enum(scaleDecoder: scaleDecoder))
        case 6: self = .compact(try Compact(scaleDecoder: scaleDecoder))
        case 7: self = .bitSequence(try BitSequence(scaleDecoder: scaleDecoder))
        default:
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Unexpected kind of TypeMetadata.Def: \(index)",
                    underlyingError: nil
                )
            )
        }
    }
}

// MARK: TypeMetadata.Def.Composite

extension TypeMetadata.Def {
    public struct Composite {
        public let fields: [Field]
    }
}

extension TypeMetadata.Def.Composite: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try fields.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.fields = try [Field](scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.Composite.Field

extension TypeMetadata.Def.Composite {
    public struct Field {
        public let name: String?
        public let type: BigUInt
        public let typeName: String?
        public let docs: [String]
    }
}

extension TypeMetadata.Def.Composite.Field: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try ScaleOption(value: name).encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
        try ScaleOption(value: typeName).encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.name = try ScaleOption<String>(scaleDecoder: scaleDecoder).value
        self.type = try BigUInt(scaleDecoder: scaleDecoder)
        self.typeName = try ScaleOption<String>(scaleDecoder: scaleDecoder).value
        self.docs = try [String](scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.Variant

extension TypeMetadata.Def {
    public struct Variant {
        public let variants: [Item]
    }
}

extension TypeMetadata.Def.Variant: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try variants.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.variants = try [Item](scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.Variant.Item

extension TypeMetadata.Def.Variant {
    public struct Item {
        public let name: String
        public let fields: [TypeMetadata.Def.Composite.Field]
        public let index: UInt8
        public let docs: [String]
    }
}

extension TypeMetadata.Def.Variant.Item: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try fields.encode(scaleEncoder: scaleEncoder)
        try index.encode(scaleEncoder: scaleEncoder)
        try docs.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.name = try String(scaleDecoder: scaleDecoder)
        self.fields = try [TypeMetadata.Def.Composite.Field](scaleDecoder: scaleDecoder)
        self.index = try UInt8(scaleDecoder: scaleDecoder)
        self.docs = try [String](scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.Sequence

extension TypeMetadata.Def {
    public struct Sequence {
        public let type: BigUInt
    }
}

extension TypeMetadata.Def.Sequence: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.type = try BigUInt(scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.Array

extension TypeMetadata.Def {
    public struct Array {
        public let length: UInt32
        public let type: BigUInt
    }
}

extension TypeMetadata.Def.Array: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try length.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.length = try UInt32(scaleDecoder: scaleDecoder)
        self.type = try BigUInt(scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.Enum

extension TypeMetadata.Def {
    public enum Enum: UInt8 {
        case bool
        case char
        case string
        case u8
        case u16
        case u32
        case u64
        case u128
        case u256
        case i8
        case i16
        case i32
        case i64
        case i128
        case i256
    }
}

extension TypeMetadata.Def.Enum: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try rawValue.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        let rawValue = try UInt8(scaleDecoder: scaleDecoder)
        guard let value = Self(rawValue: rawValue) else {
            throw DecodingError.typeMismatch(
                Self.self,
                .init(
                    codingPath: [],
                    debugDescription: "Unexpected kind of TypeMetadata.Def.Enum: \(rawValue)",
                    underlyingError: nil
                )
            )
        }

        self = value
    }
}

// MARK: TypeMetadata.Def.Compact

extension TypeMetadata.Def {
    public struct Compact {
        public let type: BigUInt
    }
}

extension TypeMetadata.Def.Compact: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.type = try BigUInt(scaleDecoder: scaleDecoder)
    }
}

// MARK: TypeMetadata.Def.BitSequence

extension TypeMetadata.Def {
    public struct BitSequence {
        public let store: BigUInt
        public let order: BigUInt
    }
}

extension TypeMetadata.Def.BitSequence: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try store.encode(scaleEncoder: scaleEncoder)
        try order.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.store = try BigUInt(scaleDecoder: scaleDecoder)
        self.order = try BigUInt(scaleDecoder: scaleDecoder)
    }
}
