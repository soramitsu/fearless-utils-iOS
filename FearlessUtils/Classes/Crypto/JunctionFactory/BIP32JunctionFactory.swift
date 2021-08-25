import Foundation
import BigInt
import IrohaCrypto

final public class BIP32JunctionFactory: JunctionFactory {
    public override init() {
        super.init()
    }

    internal override func createChaincodeFromJunction(_ junction: String, type: ChaincodeType) throws -> Chaincode {
        guard
            var numericJunction = UInt32(junction),
            numericJunction < 0x80000000
        else {
            throw JunctionFactoryError.invalidBIP32Junction
        }

        if type == .hard {
            numericJunction |= 0x80000000
        }

        let junctionBytes = withUnsafeBytes(of: numericJunction.bigEndian) {
            Data($0)
        }

        return Chaincode(data: junctionBytes, type: type)
    }
}
