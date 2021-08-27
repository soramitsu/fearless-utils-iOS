import Foundation

public enum JSONRPCEngineError: Error {
    case emptyResult
    case remoteCancelled
    case clientCancelled
    case unknownError
}

public protocol JSONRPCResponseHandling {
    func handle(data: Data)
    func handle(error: Error)
}

public struct JSONRPCRequest: Equatable {
    public let requestId: UInt16
    public let data: Data
    public let options: JSONRPCOptions
    public let responseHandler: JSONRPCResponseHandling?

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.requestId == rhs.requestId }
}

struct JSONRPCResponseHandler<T: Decodable>: JSONRPCResponseHandling {
    let completionClosure: (Result<T, Error>) -> Void

    func handle(data: Data) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(JSONRPCData<T>.self, from: data)

            completionClosure(.success(response.result))

        } catch {
            completionClosure(.failure(error))
        }
    }

    func handle(error: Error) {
        completionClosure(.failure(error))
    }
}

public struct JSONRPCOptions {
    let resendOnReconnect: Bool

    init(resendOnReconnect: Bool = true) {
        self.resendOnReconnect = resendOnReconnect
    }
}

protocol JSONRPCSubscribing: AnyObject {
    var requestId: UInt16 { get }
    var requestData: Data { get }
    var requestOptions: JSONRPCOptions { get }
    var remoteId: String? { get set }

    func handle(data: Data) throws
    func handle(error: Error, unsubscribed: Bool)
}

final class JSONRPCSubscription<T: Decodable>: JSONRPCSubscribing {
    let requestId: UInt16
    let requestData: Data
    let requestOptions: JSONRPCOptions
    var remoteId: String?

    private lazy var jsonDecoder = JSONDecoder()

    let updateClosure: (T) -> Void
    let failureClosure: (Error, Bool) -> Void

    init(
        requestId: UInt16,
        requestData: Data,
        requestOptions: JSONRPCOptions,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    ) {
        self.requestId = requestId
        self.requestData = requestData
        self.requestOptions = requestOptions
        self.updateClosure = updateClosure
        self.failureClosure = failureClosure
    }

    func handle(data: Data) throws {
        let entity = try jsonDecoder.decode(T.self, from: data)
        updateClosure(entity)
    }

    func handle(error: Error, unsubscribed: Bool) {
        failureClosure(error, unsubscribed)
    }
}

public protocol JSONRPCEngine: AnyObject {
    func callMethod<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        options: JSONRPCOptions,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16

    func subscribe<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        updateClosure: @escaping (T) -> Void,
        failureClosure: @escaping (Error, Bool) -> Void
    )
        throws -> UInt16

    func cancelForIdentifier(_ identifier: UInt16)
}

public extension JSONRPCEngine {
    func callMethod<P: Encodable, T: Decodable>(
        _ method: String,
        params: P?,
        completion closure: ((Result<T, Error>) -> Void)?
    ) throws -> UInt16 {
        try callMethod(
            method,
            params: params,
            options: JSONRPCOptions(),
            completion: closure
        )
    }
}
