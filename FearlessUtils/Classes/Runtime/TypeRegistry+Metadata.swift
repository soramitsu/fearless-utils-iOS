import Foundation

public extension TypeRegistry {
    static func createFromRuntimeMetadata(_ runtimeMetadata: RuntimeMetadata,
                                          additionalTypes: Set<String> = []) throws -> TypeRegistry {
        var allTypes: Set<String> = additionalTypes

        let schemaResolver = runtimeMetadata.schemaResolver
        for module in runtimeMetadata.modules {
            if let storage = module.storage {
                for storageEntry in storage.entries {
                    switch storageEntry.type {
                    case .plain(let plain):
                        allTypes.insert(try plain.value(using: schemaResolver))
                    case .map(let map):
                        allTypes.insert(map.key)
                        allTypes.insert(map.value)
                    case .doubleMap(let map):
                        allTypes.insert(map.key1)
                        allTypes.insert(map.key2)
                        allTypes.insert(map.value)
                    case .nMap(let nMap):
                        try nMap.keys(using: schemaResolver).forEach { allTypes.insert($0) }
                        allTypes.insert(try nMap.value(using: schemaResolver))
                    }
                }
            }

            if let calls = try module.calls(using: schemaResolver) {
                let callTypes = calls.flatMap { $0.arguments.map { $0.type }}
                allTypes.formUnion(callTypes)
            }

            if let events = try module.events(using: schemaResolver) {
                let eventTypes = events.flatMap { $0.arguments }
                allTypes.formUnion(eventTypes)
            }

            let constantTypes = try module.constants.map { try $0.type(using: schemaResolver) }
            allTypes.formUnion(constantTypes)
        }

        let jsonDic: [String: JSON] = allTypes.reduce(into: [String: JSON]()) { (result, item) in
            result[item] = .stringValue(item)
        }

        let json = JSON.dictionaryValue(["types": .dictionaryValue(jsonDic)])

        return try TypeRegistry.createFromTypesDefinition(json: json,
                                                          additionalNodes: [])
    }
}
