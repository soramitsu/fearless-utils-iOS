import Foundation

public protocol NodeResolver: class {
    func resolve(for key: String) -> Node?
}

public struct ProxyNode: Node {
    public let typeName: String
    public weak var resolver: NodeResolver?

    public init(typeName: String, resolver: NodeResolver) {
        self.typeName = typeName
        self.resolver = resolver
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let undelyingNode = resolver?.resolve(for: typeName) else {
            throw DynamicScaleCoderError.unresolverType(name: typeName)
        }

       try undelyingNode.accept(encoder: encoder, value: value)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        guard let undelyingNode = resolver?.resolve(for: typeName) else {
            throw DynamicScaleCoderError.unresolverType(name: typeName)
        }

        return try undelyingNode.accept(decoder: decoder)
    }
}