import Foundation

// MARK: - Protocol

public protocol RuntimeFunctionArgumentMetadata {
    var name: String { get }
    var type: String { get }
}

// MARK: - V1

extension RuntimeMetadataV1 {
    public struct FunctionArgumentMetadata: RuntimeFunctionArgumentMetadata {
        public let name: String
        public let type: String

        public init(name: String, type: String) {
            self.name = name
            self.type = type
        }
    }
}

extension RuntimeMetadataV1.FunctionArgumentMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try name.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.name = try String(scaleDecoder: scaleDecoder)
        self.type = try String(scaleDecoder: scaleDecoder)
    }
}

// MARK: - V14

extension RuntimeMetadataV14 {
    public typealias FunctionArgumentMetadata = RuntimeMetadataV1.FunctionArgumentMetadata
}
