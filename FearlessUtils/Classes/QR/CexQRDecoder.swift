import Foundation

public class CexQRDecoder: CexQRDecodable {
    
    public init() {}
    
    public func decode(data: Data) throws -> QRInfo {
        guard let address = String(data: data, encoding: .utf8) else {
            throw QRDecoderError.brokenFormat
        }
        
        return CexQRInfo(address: address)
    }
}
