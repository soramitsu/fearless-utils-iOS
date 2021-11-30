import Foundation
import BigInt

// MARK: - Schema

public struct Schema: ScaleCodable {
    public let types: [SchemaItem]

    public init(types: [SchemaItem]) {
        self.types = types
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        try types.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.types = try [SchemaItem](scaleDecoder: scaleDecoder)
    }
}

// MARK: - Resolver

extension Schema {
    public struct Resolver {
        private let schema: Schema?
        public init(schema: Schema?) {
            self.schema = schema
        }

        public func typeMetadata(for index: BigUInt?) throws -> TypeMetadata {
            guard let schema = schema else {
                throw Error.schemaNotProvided
            }

            guard let index = index else {
                throw Error.wrongData
            }

            guard let type = schema.types.first(where: { $0.id == index })?.type else {
                throw Error.keyNotFound
            }

            return type
        }

        public func typeName(for index: BigUInt?) throws -> String {
            try typeMetadata(for: index).path.joined(separator: "::")
        }
    }
}

extension Schema.Resolver {
    public enum Error: Swift.Error {
        case schemaNotProvided
        case wrongData
        case keyNotFound
    }
}

// MARK: - Item

public struct SchemaItem: ScaleCodable {
    public let id: BigUInt
    public let type: TypeMetadata

    public func encode(scaleEncoder: ScaleEncoding) throws {
        try id.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.id = try BigUInt(scaleDecoder: scaleDecoder)
        self.type = try TypeMetadata(scaleDecoder: scaleDecoder)
    }
}
