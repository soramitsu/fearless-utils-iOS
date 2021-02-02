import Foundation

public enum TypeRegistryError: Error {
    case unexpectedJson
    case invalidKey(String)
}

protocol TypeRegistering {
    func register(typeName: String, json: JSON) -> Node
}

/**
 *  Class is designed to store types definitions used in Substrate Runtime
 *  and described by a json. The implementation parses the json and
 *  tries to construct a graph. Each node of the graph is identified by type's name
 *  and describes type's specifics such as which fields are there and on which types it depends on.
 *  Each node is create by a corresponding factory which uses specific parser to process type definitions.
 *
 *  Currently the following types are supported:
 *  - Structure (an ordered collection of fields)
 *  - Enum mapping (custom type with named set of values)
 *  - Enum collection (custom type with a list of values)
 *  - Numeric set (a name set represented by a bit vector)
 *  - Vector (unbounded list of values)
 *  - Option (optional value)
 *  - Compact (special type for compact representation of the integer)
 *  - Fixed array (a list of values with a given length)
 *  - Alias (just a term that represents an alias to other type)
 *
 *  The main purpose of the registry is to support SCALE coding/decoding in the runtime
 *  with ability to allow type definitions updates.
 */

public class TypeRegistry {
    private var graph: [String: Node] = [:]
    private var nodeFactory: TypeNodeFactoryProtocol
    private var typeResolver: TypeResolving

    public var registeredTypes: [Node] { graph.keys.compactMap { graph[$0] } }

    init(json: JSON, nodeFactory: TypeNodeFactoryProtocol, typeResolver: TypeResolving) throws {
        self.nodeFactory = nodeFactory
        self.typeResolver = typeResolver

        try parse(json: json)
        resolveGenerics()
    }

    public func node(for key: String) -> Node? {
        if let node = graph[key] {
            return node
        }

        if let resolvedKey = typeResolver.resolve(typeName: key, using: Set(graph.keys)) {
            return graph[resolvedKey]
        }

        return nil
    }

    // MARK: Private

    private func parse(json: JSON) throws {
        guard let dict = json.dictValue else {
            throw TypeRegistryError.unexpectedJson
        }

        let keyParser = TermParser.generic()

        let refinedDict = try dict.reduce(into: [String: JSON]()) { (result, item) in
            if let type = keyParser.parse(json: .stringValue(item.key))?.first?.stringValue {
                result[type] = item.value
            } else {
                throw TypeRegistryError.invalidKey(item.key)
            }
        }

        for typeName in refinedDict.keys {
            graph[typeName] = GenericNode(typeName: typeName)
        }

        for item in refinedDict {
            if let node = try nodeFactory.buildNode(from: item.value,
                                                    typeName: item.key,
                                                    mediator: self) {
                graph[item.key] = node
            }
        }
    }

    private func resolveGenerics() {
        let allTypeNames = Set(graph.keys)

        let genericTypeNames = allTypeNames.filter { graph[$0] is GenericNode }

        for genericTypeName in genericTypeNames {
            if let resolvedKey = typeResolver.resolve(typeName: genericTypeName,
                                                      using: allTypeNames.subtracting([genericTypeName])) {
                graph[genericTypeName] = ProxyNode(typeName: resolvedKey, resolver: self)
            }
        }
    }
}

public extension TypeRegistry {
    static func createFromTypesDefinition(data: Data) throws -> TypeRegistry {
        let jsonDecoder = JSONDecoder()
        let json = try jsonDecoder.decode(JSON.self, from: data)

        guard let types = json.types else {
            throw TypeRegistryError.unexpectedJson
        }

        let factories: [TypeNodeFactoryProtocol] = [
            StructNodeFactory(parser: TypeMappingParser.structure()),
            EnumNodeFactory(parser: TypeMappingParser.enumeration()),
            EnumValuesNodeFactory(parser: TypeValuesParser.enumeration()),
            NumericSetNodeFactory(parser: TypeSetParser.generic()),
            TupleNodeFactory(parser: ComponentsParser.tuple()),
            FixedArrayNodeFactory(parser: FixedArrayParser.generic()),
            VectorNodeFactory(parser: RegexParser.vector()),
            OptionNodeFactory(parser: RegexParser.option()),
            CompactNodeFactory(parser: RegexParser.compact()),
            AliasNodeFactory(parser: TermParser.generic())
        ]

        let resolvers: [TypeResolving] = [
            CaseInsensitiveResolver()
        ]

        return try TypeRegistry(json: types,
                                nodeFactory: OneOfTypeNodeFactory(children: factories),
                                typeResolver: OneOfTypeResolver(children: resolvers))
    }
}

extension TypeRegistry: TypeRegistering {
    func register(typeName: String, json: JSON) -> Node {
        let proxy = ProxyNode(typeName: typeName, resolver: self)

        guard graph[typeName] == nil else {
            return proxy
        }

        graph[typeName] = GenericNode(typeName: typeName)

        if let node = try? nodeFactory.buildNode(from: json, typeName: typeName, mediator: self) {
            graph[typeName] = node
        }

        return proxy
    }
}

extension TypeRegistry: NodeResolver {
    public func resolve(for key: String) -> Node? { graph[key] }
}
