import Foundation

public protocol CexQRDecodable: QRDecodable {}

public struct CexQRInfo: QRInfo, Equatable {
    public let address: String
    
    public init(address: String) {
        self.address = address
    }
}
