import Foundation

public class GenericBlockNode: Node {
    public var typeName: String { GenericType.block.name }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        throw DynamicScaleCoderError.unresolvedType(name: typeName)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        throw DynamicScaleCoderError.unresolvedType(name: typeName)
    }
}
