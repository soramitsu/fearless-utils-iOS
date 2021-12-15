import Foundation
import BigInt

public class RuntimeSchemaResolver: TypeResolving {
    private let schemaResolver: Schema.Resolver
    
    public init(schemaResolver: Schema.Resolver) {
        self.schemaResolver = schemaResolver
    }
    
    public func resolve(typeName: String, using availableNames: Set<String>) -> String? {
        guard let id = BigUInt(typeName) else { return nil }
        return try? schemaResolver.typeName(for: id)
    }
}
