import Foundation
import BigInt
import IrohaCrypto

public struct BIP32JunctionFactory: JunctionFactoryProtocol {
    static let passwordSeparator = "///"
    static let hardSeparator = "//"
    static let softSeparator = "/"

    public init() {}

    public func parse(path: String) throws -> JunctionResult {
        guard path.hasPrefix(Self.softSeparator) else {
            throw JunctionFactoryError.invalidStart
        }

        let passwordIncludedComponents = path.components(separatedBy: Self.passwordSeparator)

        guard let junctionsPath = passwordIncludedComponents.first else {
            throw JunctionFactoryError.emptyPath
        }

        guard passwordIncludedComponents.count <= 2 else {
            throw JunctionFactoryError.multiplePassphrase
        }

        let password: String?

        if passwordIncludedComponents.count == 2 {
            password = passwordIncludedComponents.last
        } else {
            password = nil
        }

        if let existingPassword = password, existingPassword.isEmpty {
            throw JunctionFactoryError.emptyPassphrase
        }

        let chaincodes = try parseChaincodesFromJunctionPath(junctionsPath)

        return JunctionResult(chaincodes: chaincodes, password: password)
    }

    private func parseChaincodesFromJunctionPath(_ junctionsPath: String) throws -> [Chaincode] {
        return try junctionsPath
            .components(separatedBy: Self.hardSeparator)
            .map { component in

                var chaincodes: [Chaincode] = []

                let subcomponents = component.components(separatedBy: Self.softSeparator)

                guard let hardJunction = subcomponents.first else {
                    throw JunctionFactoryError.emptyJunction
                }

                if !hardJunction.isEmpty {
                    let hardChaincode = try createChaincodeFromJunction(hardJunction, type: .hard)
                    chaincodes.append(hardChaincode)
                }

                let softJunctions: [Chaincode] = try subcomponents[1...].map { softJunction in
                    try createChaincodeFromJunction(softJunction, type: .soft)
                }

                chaincodes.append(contentsOf: softJunctions)

                return chaincodes
            }.reduce([Chaincode]()) { (result, chaincodes) in
                return result + chaincodes
            }
    }

    private func createChaincodeFromJunction(_ junction: String, type: ChaincodeType) throws -> Chaincode {
        guard
            var numericJunction = UInt32(junction),
            numericJunction < 0x80000000
        else {
            throw JunctionFactoryError.wrongBIP32Junction
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
