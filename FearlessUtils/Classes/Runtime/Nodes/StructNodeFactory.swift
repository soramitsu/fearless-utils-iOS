import Foundation

class StructNodeFactory: TypeNodeFactoryProtocol {
    let parser: TypeParser

    init(parser: TypeParser) {
        self.parser = parser
    }

    func buildNode(from json: JSON, typeName: String, mediator: TypeRegistering) throws -> Node? {
        guard let children = parser.parse(json: json) else {
            return nil
        }

        let childrenNodes: [NameNode] = try children.map { child in
            guard let nameAndValueType = child.arrayValue,
                  nameAndValueType.count == 2,
                  let name = nameAndValueType.first?.stringValue,
                  let value = nameAndValueType.last else {
                throw TypeNodeFactoryError.unexpectedParsingResult(typeName: typeName)
            }

            let node = mediator.register(typeName: name, json: value)

            return NameNode(name: name, node: node)
        }

        return StructNode(typeName: typeName, typeMapping: childrenNodes)
    }
}
