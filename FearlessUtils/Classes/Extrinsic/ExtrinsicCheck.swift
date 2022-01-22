import Foundation

enum ExtrinsicCheck: String, CaseIterable {
    case specVersion = "frame_system::extensions::check_spec_version::CheckSpecVersion"
    case txVersion = "frame_system::extensions::check_tx_version::CheckTxVersion"
    case genesis = "frame_system::extensions::check_genesis::CheckGenesis"
    case mortality = "frame_system::extensions::check_mortality::CheckMortality"
    case nonce = "frame_system::extensions::check_nonce::CheckNonce"
    case weight = "frame_system::extensions::check_weight::CheckWeight"
    case txPayment = "pallet_transaction_payment::ChargeTransactionPayment"
    case attests = "polkadot_runtime_common::claims::PrevalidateAttests"
    
    private static var overridenTypes: [String: String] = [:]
    
    static func from(string: String) -> Self? {
        if let check = ExtrinsicCheck(rawValue: string) {
            return check
        }
        
        if let overridenType = overridenTypes[string] {
            return from(string: overridenType)
        }
        
        let typeName = string.components(separatedBy: "::").last
        for check in Self.allCases {
            if let checkTypeName = check.rawValue.components(separatedBy: "::").last, checkTypeName == typeName {
                overridenTypes[string] = check.rawValue
                return from(string: check.rawValue)
            }
        }
        
        return nil
    }
}
