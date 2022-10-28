import Foundation

public extension TypeRegistry {
    static func createFromRuntimeMetadata(
        _ runtimeMetadata: RuntimeMetadata,
        additionalTypes: Set<String> = [],
        usedRuntimePaths: [String: [String]]
    ) throws -> TypeRegistry {
        let schemaResolver = runtimeMetadata.schemaResolver
        var jsonDic: [String: JSON] = [:]
        var runtimeModules = runtimeMetadata.modules
        
        try usedRuntimePaths.forEach { (moduleName, callNames) in
            guard
                let runtimeModuleIndex = runtimeModules.firstIndex(where: {
                    $0.name == moduleName
                })
            else {
                return
            }

            if let storage = runtimeModules[runtimeModuleIndex].storage {
                var storageEntrys = storage.entries
                
                try callNames.forEach { callName in
                    guard
                        let storageEntryIndex = storageEntrys.firstIndex(where: {
                            $0.name == callName
                        })
                    else {
                        return
                    }
                    
                    switch storageEntrys[storageEntryIndex].type {
                    case .plain(let plain):
                        let plainType = try plain.value(using: schemaResolver)
                        jsonDic[plainType] = .stringValue(plainType)
                    case .map(let map):
                        jsonDic[map.key] = .stringValue(map.key)
                        jsonDic[map.value] = .stringValue(map.value)
                    case .doubleMap(let map):
                        jsonDic[map.key1] = .stringValue(map.key1)
                        jsonDic[map.key2] = .stringValue(map.key2)
                        jsonDic[map.value] = .stringValue(map.value)
                    case .nMap(let nMap):
                        try nMap.keys(using: schemaResolver).forEach {
                            jsonDic[$0] = .stringValue($0)
                        }
                        let nMapValue = try nMap.value(using: schemaResolver)
                        jsonDic[nMapValue] = .stringValue(nMapValue)
                    }
                    
                    storageEntrys.remove(at: storageEntryIndex)
                }
            }

            if let events = try runtimeModules[runtimeModuleIndex].events(using: schemaResolver) {
                events.forEach { event in
                    event.arguments.forEach { argument in
                        jsonDic[argument] = .stringValue(argument)
                    }
                }
            }

            try runtimeModules[runtimeModuleIndex].constants.forEach({ constant in
                let type = try constant.type(using: schemaResolver)
                jsonDic[type] = .stringValue(type)
            })
            
            runtimeModules.remove(at: runtimeModuleIndex)
        }

        let json = JSON.dictionaryValue(["types": .dictionaryValue(jsonDic)])

        return try TypeRegistry.createFromTypesDefinition(
            json: json,
            additionalNodes: [],
            schemaResolver: schemaResolver
        )
    }
}
