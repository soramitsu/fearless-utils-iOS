import Foundation

public class GenericNode: Node {
    public let typeName: String

    public init(typeName: String) {
        self.typeName = typeName
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        throw DynamicScaleCoderError.unresolvedType(name: typeName)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        throw DynamicScaleCoderError.unresolvedType(name: typeName)
    }
}
