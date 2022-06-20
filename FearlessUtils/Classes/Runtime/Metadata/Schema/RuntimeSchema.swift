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
    public final class Resolver {
        
        // MARK: - Private properties
        private struct TypeResolved {
            let metadata: TypeMetadata?
        }
        
        private let schema: Schema?
        private var resolvedTypes: [String: TypeResolved] = [:]
        
        // MARK: - Constructor
        public init(schema: Schema?) {
            self.schema = schema
            if let mappedSchema = try? mapSchemaToDictionary() {
                self.resolvedTypes = mappedSchema
            }
        }
        
        
        // MARK: - Public methods
        public func resolveType(json: JSON) throws -> TypeMetadata? {
            guard let string = json.stringValue else { return nil }
            
            if let index = BigUInt(string) {
                return try typeMetadata(for: index)
            }
            
            return try resolveType(name: string)
        }
        
        public func resolveType(name: String) throws -> TypeMetadata? {
            var metadata: TypeMetadata? = nil
            if let type = resolvedTypes[name] {
                metadata = type.metadata
            }
            
            return metadata
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
            try typeName(for: try typeMetadata(for: index))
        }
        
        public func typeName(for type: TypeMetadata) throws -> String {
            let name = try _typeName(for: type)
            if resolvedTypes[name]?.metadata == nil {
                resolvedTypes[name] = TypeResolved(metadata: type)
            }
            
            return name
        }
        
        // MARK: - Private methods
        
        private func mapSchemaToDictionary() throws -> [String: TypeResolved] {
            var result = [String: TypeResolved]()
            guard let items = schema?.types else {
                return result
            }
            do {
                let mappedSchema = try items.reduce([String: TypeResolved]()) { (dict, schemaItem) -> [String: TypeResolved] in
                    var dict = dict
                    let key = try typeName(for: schemaItem.type)
                    dict[key] = TypeResolved(metadata: schemaItem.type)
                    return dict
                }
                result = mappedSchema
            }
            return result
        }
        
        private var ignoredGenericTypes: [String] {
            [KnownType.address.name] + ExtrinsicCheck.allCases.map { $0.rawValue }
        }

        // swiftlint:disable cyclomatic_complexity function_body_length
        private func _typeName(for type: TypeMetadata) throws -> String {
            switch type.def {
            case .composite, .variant:
                guard type.path.count > 0 else {
                    throw Error.wrongData
                }
                var name = type.path.joined(separator: "::")
                
                if !type.params.isEmpty, !ignoredGenericTypes.contains(name) {
                    let paramNames = try type.params
                        .map {
                            var name = $0.name
                            if let typeName = try $0.type.map({ try typeName(for: $0) }) {
                                name += ": \(typeName)"
                            }

                            return name
                        }
                        .joined(separator: ", ")

                    name += "<\(paramNames)>"
                }

                return name

            case let .sequence(value):
                return "Vec<\(try typeName(for: value.type))>"

            case let .array(value):
                return "[\(try typeName(for: value.type)); \(value.length)]"

            case let .tuple(value):
                let paramNames = try value.map { try typeName(for: $0) }.joined(separator: ", ")
                return "(\(paramNames))"

            case let .primitive(value):
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
                return "Compact<\(try typeName(for: value.type))>"

            case let .bitSequence(value):
                let paramNames = [
                    try typeName(for: value.order),
                    try typeName(for: value.store)
                ].joined(separator: ", ")
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
