import XCTest
import FearlessUtils
import IrohaCrypto

class BIP32KeypairDeriviationTests: XCTestCase {

    func testBIP32DerivationPath() throws {
        try performTest(filename: "BIP32HDKD", keypairFactory: BIP32KeypairFactory(), useMiniSeed: false)
    }

    func testBIP32DerivationPathStandardData() throws {
        try performSeedReadyTest(filename: "BIP32HDKDStandard", keypairFactory: BIP32KeypairFactory())
    }

    private func performTest(filename: String, keypairFactory: KeypairFactoryProtocol, useMiniSeed: Bool = true) throws {
        guard let url = Bundle(for: KeypairDeriviationTests.self)
            .url(forResource: filename, withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([KeypairDeriviation].self, from: testData)

            let junctionFactory = BIP32JunctionFactory()
            let seedFactory = SeedFactory()

            for item in items {
                let result: JunctionResult

                if !item.path.isEmpty {
                    result = try junctionFactory.parse(path: item.path)
                } else {
                    result = JunctionResult(chaincodes: [], password: nil)
                }

                let seedResult = try seedFactory.deriveNativeSeed(from: item.mnemonic,
                                                            password: result.password ?? "")

                let seed = useMiniSeed ? seedResult.seed.miniSeed: seedResult.seed

                let keypair = try keypairFactory.createKeypairFromSeed(seed,
                                                                       chaincodeList: result.chaincodes)

                let publicKey = keypair.publicKey().rawData()

                let expectedPublicKey = try Data(hexString: item.publicKey)

                if publicKey != expectedPublicKey {
                    XCTFail("Failed for path: \(item.path)")
                }
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    private func performSeedReadyTest(filename: String, keypairFactory: KeypairFactoryProtocol) throws {
        guard let url = Bundle(for: KeypairDeriviationTests.self)
            .url(forResource: filename, withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([KeypairDeriviation].self, from: testData)

            let junctionFactory = BIP32JunctionFactory()

            for item in items {
                let result: JunctionResult

                if !item.path.isEmpty {
                    result = try junctionFactory.parse(path: item.path)
                } else {
                    result = JunctionResult(chaincodes: [], password: nil)
                }

                let keypair = try keypairFactory.createKeypairFromSeed(Data(hexString: item.seed),
                                                                       chaincodeList: result.chaincodes)

                let publicKey = keypair.publicKey().rawData()

                let expectedPublicKey = try Data(hexString: item.publicKey)

                if publicKey != expectedPublicKey {
                    XCTFail("Failed for path: \(item.path)")
                }
            }
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
