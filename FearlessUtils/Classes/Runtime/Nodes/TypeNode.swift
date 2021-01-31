import Foundation

public protocol Node {
    var typeName: String { get }
}

public struct NameNode {
    public let name: String
    public let node: Node

    init(name: String, node: Node) {
        self.name = name
        self.node = node
    }
}

public struct GenericNode: Node {
    public let typeName: String
}

public struct StructNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }
}

public struct EnumNode: Node {
    public let typeName: String
    public let typeMapping: [NameNode]

    public init(typeName: String, typeMapping: [NameNode]) {
        self.typeName = typeName
        self.typeMapping = typeMapping
    }
}

public struct EnumValuesNode: Node {
    public let typeName: String
    public let values: [String]

    public init(typeName: String, values: [String]) {
        self.typeName = typeName
        self.values = values
    }
}

public struct SetNode: Node {
    public struct Item {
        let name: String
        let value: UInt64
    }

    public let typeName: String
    public let bitVector: [Item]
    public let itemType: Node

    init(typeName: String, bitVector: [Item], itemType: Node) {
        self.typeName = typeName
        self.bitVector = bitVector
        self.itemType = itemType
    }
}

public struct OptionNode: Node {
    public let typeName: String
    let underlying: Node
}

public struct CompactNode: Node {
    public let typeName: String
}

public struct VectorNode: Node {
    public let typeName: String
    let underlying: Node
}

public struct TupleNode: Node {
    public let typeName: String
    let innerNodes: [Node]
}

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
}
