import Foundation

public enum KnownType: String, CaseIterable {
    // primitives that may vary by network, may have different index,
    // MAY BE NOT USED by new runtime metadata implementation
    case balance = "Balance"
    case index = "Index"
    
    // name varies by network, mapping provided by remote JSON
    case call = "GenericCall"
    
    // resolved for all versions of metadata
    case phase = "frame_system::Phase"
    case address = "sp_runtime::multiaddress::MultiAddress"
    case signature = "sp_runtime::MultiSignature"

    public var name: String { rawValue }
}
