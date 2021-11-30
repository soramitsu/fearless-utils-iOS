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

        // swiftlint:disable cyclomatic_complexity function_body_length
        public func typeName(for index: BigUInt?) throws -> String {
            let type = try typeMetadata(for: index)

            let baseName = type.path.joined(separator: "::")
            func paramNames(types: [BigUInt?]) throws -> String {
                try types
                    .map { try typeName(for: $0) }
                    .joined(separator: ", ")
            }

            switch type.def {
            case .composite, .variant:
                var name = baseName
                if !type.params.isEmpty {
                    let paramNames = try paramNames(types: type.params.map { $0.type })
                    name += "<\(paramNames)>"
                }

                return name

            case let .sequence(value):
                let paramNames = try paramNames(types: [value.type])
                return "Vec<\(paramNames)>"

            case let .array(value):
                let paramNames = try paramNames(types: [value.type])
                return "[\(paramNames); \(value.length)]"

            case .tuple:
                guard !type.params.isEmpty else { throw Error.wrongData }
                let paramNames = try paramNames(types: type.params.map { $0.type })
                return "(\(paramNames))"

            case let .enum(value):
                switch value {
                case .bool: return "bool"
                case .char: return "char"
                case .string: return "str"
                case .u8: return "u8"
                case .u16: return "u16"
                case .u32: return "u32"
                case .u64: return "u64"
                case .u128: return "u128"
                case .u256: return "u256"
                case .i8: return "i8"
                case .i16: return "i16"
                case .i32: return "i32"
                case .i64: return "i64"
                case .i128: return "i128"
                case .i256: return "i256"
                }

            case let .compact(value):
                let paramNames = try paramNames(types: [value.type])
                return "Compact<\(paramNames)>"

            case let .bitSequence(value):
                let paramNames = try paramNames(types: [value.order, value.store])
                return "BitVec<\(paramNames)>"
            }
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
