import Foundation

public enum KnownType: String, CaseIterable {
    case balance = "Balance"
    case index = "Index"
    case phase = "Phase"
    case call = "Call"
    case address = "Address"
    case signature = "ExtrinsicSignature"

    public var name: String { rawValue }
}
