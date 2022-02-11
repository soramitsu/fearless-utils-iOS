import Foundation

// MARK: - Protocol

public protocol RuntimeEventMetadata {
    var name: String { get }
    var arguments: [String] { get }
    var documentation: [String] { get }
}

// MARK: - V1

extension RuntimeMetadataV1 {
    public struct EventMetadata: RuntimeEventMetadata {
        public let name: String
        public let arguments: [String]
        public let documentation: [String]

        public init(name: String, arguments: [String], documentation: [String]) {
            self.name = name
            self.arguments = arguments
            self.documentation = documentation
        }
    }
}

extension RuntimeMetadataV1.EventMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try arguments.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        arguments = try [String](scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}

// MARK: - V14

extension RuntimeMetadataV14 {
    public struct EventMetadata: RuntimeEventMetadata {
        public let name: String
        public let arguments: [String]
        public let documentation: [String]

        public init(item: TypeMetadata.Def.Variant.Item, schemaResolver: Schema.Resolver) throws {
            self.name = item.name
            self.arguments = try item.fields.map { try schemaResolver.typeName(for: $0.type) }
            self.documentation = item.docs
        }
    }
}
