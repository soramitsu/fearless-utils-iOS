import Foundation

// MARK: - Protocol

public protocol RuntimeErrorMetadata {
    var name: String { get }
    var documentation: [String] { get }
}

// MARK: - V1

extension RuntimeMetadataV1 {
    public struct ErrorMetadata: RuntimeErrorMetadata {
        public let name: String
        public let documentation: [String]

        public init(name: String, documentation: [String]) {
            self.name = name
            self.documentation = documentation
        }
    }
}

extension RuntimeMetadataV1.ErrorMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try documentation.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        name = try String(scaleDecoder: scaleDecoder)
        documentation = try [String](scaleDecoder: scaleDecoder)
    }
}

// MARK: - V14

extension RuntimeMetadataV14 {
    public typealias ErrorMetadata = RuntimeMetadataV1.ErrorMetadata
}
