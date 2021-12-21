import Foundation

enum ExtrinsicCheck: String {
    case specVersion = "frame_system::extensions::check_spec_version::CheckSpecVersion<T>"
    case txVersion = "frame_system::extensions::check_tx_version::CheckTxVersion<T>"
    case genesis = "frame_system::extensions::check_genesis::CheckGenesis<T>"
    case mortality = "frame_system::extensions::check_mortality::CheckMortality<T>"
    case nonce = "frame_system::extensions::check_nonce::CheckNonce<T>"
    case weight = "frame_system::extensions::check_weight::CheckWeight<T>"
    case txPayment = "pallet_transaction_payment::ChargeTransactionPayment<T>"
    case attests = "polkadot_runtime_common::claims::PrevalidateAttests<T>"
}
