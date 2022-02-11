import Foundation
import BigInt

public protocol RuntimeMetadataProtocol: ScaleCodable {
    var schema: Schema? { get }
    var modules: [RuntimeModuleMetadata] { get }
    var extrinsic: RuntimeExtrinsicMetadata { get }
}

public final class RuntimeMetadata {
    public let metaReserved: UInt32
    public let version: UInt8
    public lazy var schemaResolver = Schema.Resolver(schema: schema)

    private let wrapped: RuntimeMetadataProtocol
    private init(
        wrapping runtimeMetadata: RuntimeMetadataProtocol,
        metaReserved: UInt32,
        version: UInt8
    ) {
        self.metaReserved = metaReserved
        self.version = version
        self.wrapped = runtimeMetadata
    }

    public func getFunction(from module: String, with name: String) throws -> RuntimeFunctionMetadata? {
        try wrapped.modules
            .first { $0.name == module }?
            .calls(using: schemaResolver)?
            .first { $0.name == name }
    }

    public func getModuleIndex(_ name: String) -> UInt8? {
        wrapped.modules.first(where: { $0.name == name })?.index
    }

    public func getCallIndex(in moduleName: String, callName: String) throws -> UInt8? {
        guard let index = try wrapped.modules
                .first(where: { $0.name == moduleName })?
                .calls(using: schemaResolver)?
                .firstIndex(where: { $0.name == callName})
        else {
            return nil
        }

        return UInt8(index)
    }

    public func getStorageMetadata(in moduleName: String, storageName: String) -> RuntimeStorageEntryMetadata? {
        wrapped.modules.first(where: { $0.name == moduleName })?
            .storage?.entries.first(where: { $0.name == storageName})
    }

    public func getConstant(in moduleName: String, constantName: String) -> RuntimeModuleConstantMetadata? {
        wrapped.modules.first(where: { $0.name == moduleName })?
            .constants.first(where: { $0.name == constantName})
    }
}

extension RuntimeMetadata: RuntimeMetadataProtocol {
    public var schema: Schema? { wrapped.schema }
    public var modules: [RuntimeModuleMetadata] { wrapped.modules }
    public var extrinsic: RuntimeExtrinsicMetadata { wrapped.extrinsic }
}

extension RuntimeMetadata: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try metaReserved.encode(scaleEncoder: scaleEncoder)
        try version.encode(scaleEncoder: scaleEncoder)
        try wrapped.encode(scaleEncoder: scaleEncoder)
    }

    public convenience init(scaleDecoder: ScaleDecoding) throws {
        let metaReserved = try UInt32(scaleDecoder: scaleDecoder)
        let version = try UInt8(scaleDecoder: scaleDecoder)
        
        let wrapped: RuntimeMetadataProtocol
        if version >= 14 {
            wrapped = try RuntimeMetadataV14(scaleDecoder: scaleDecoder)
        } else {
            wrapped = try RuntimeMetadataV1(scaleDecoder: scaleDecoder)
        }
        
        self.init(wrapping: wrapped, metaReserved: metaReserved, version: version)
    }
}

extension RuntimeMetadata {
    public static func v1(
        modules: [RuntimeMetadataV1.ModuleMetadata],
        extrinsic: RuntimeMetadataV1.ExtrinsicMetadata
    ) -> RuntimeMetadata {
        .init(
            wrapping: RuntimeMetadataV1(modules: modules, extrinsic: extrinsic),
            metaReserved: 1,
            version: 1
        )
    }

    public static func v14(
        types: [SchemaItem],
        modules: [RuntimeMetadataV14.ModuleMetadata],
        extrinsic: RuntimeMetadataV14.ExtrinsicMetadata
    ) -> RuntimeMetadata {
        .init(
            wrapping: RuntimeMetadataV14(types: types, modules: modules, extrinsic: extrinsic, type: 603),
            metaReserved: 14,
            version: 14
        )
    }
}

// MARK: - RuntimeMetadata V1

public struct RuntimeMetadataV1: RuntimeMetadataProtocol, ScaleCodable {
    public let schema: Schema? = nil

    private let _modules: [ModuleMetadata]
    public var modules: [RuntimeModuleMetadata] { _modules }

    private let _extrinsic: ExtrinsicMetadata
    public var extrinsic: RuntimeExtrinsicMetadata { _extrinsic }

    init(modules: [ModuleMetadata], extrinsic: ExtrinsicMetadata) {
        _modules = modules
        _extrinsic = extrinsic
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        try _modules.encode(scaleEncoder: scaleEncoder)
        try _extrinsic.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        _modules = try [ModuleMetadata](scaleDecoder: scaleDecoder)
        _extrinsic = try ExtrinsicMetadata(scaleDecoder: scaleDecoder)
    }
}

// MARK: - RuntimeMetadata V14

public struct RuntimeMetadataV14: RuntimeMetadataProtocol, ScaleCodable {
    private let _schema: Schema
    public var schema: Schema? { _schema }

    private let _modules: [ModuleMetadata]
    public var modules: [RuntimeModuleMetadata] { _modules }

    private let _extrinsic: ExtrinsicMetadata
    public var extrinsic: RuntimeExtrinsicMetadata { _extrinsic }
    
    private let type: BigUInt

    init(types: [SchemaItem], modules: [ModuleMetadata], extrinsic: ExtrinsicMetadata, type: BigUInt) {
        self._schema = Schema(types: types)
        self._modules = modules
        self._extrinsic = extrinsic
        self.type = type
    }

    public func encode(scaleEncoder: ScaleEncoding) throws {
        try _schema.encode(scaleEncoder: scaleEncoder)
        try _modules.encode(scaleEncoder: scaleEncoder)
        try _extrinsic.encode(scaleEncoder: scaleEncoder)
        try type.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        _schema = try Schema(scaleDecoder: scaleDecoder)
        _modules = try [ModuleMetadata](scaleDecoder: scaleDecoder)
        _extrinsic = try ExtrinsicMetadata(scaleDecoder: scaleDecoder)
        type = try BigUInt(scaleDecoder: scaleDecoder)
    }
}
