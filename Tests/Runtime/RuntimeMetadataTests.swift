import XCTest
import FearlessUtils

class RuntimeMetadataTests: XCTestCase {

    func testWestendRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "westend-metadata")
    }

    func testKusamaRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "kusama-metadata")
    }

    func testPolkadotRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "polkadot-metadata")
    }

    func testStatemineRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "statemine-metadata")
    }

    func testFetchStorage() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getStorageMetadata(in: "System", storageName: "Account"))
        XCTAssertNil(metadata.getStorageMetadata(in: "System", storageName: "account"))
    }

    func testFetchConstant() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getConstant(in: "Staking", constantName: "SlashDeferDuration"))
        XCTAssertNil(metadata.getStorageMetadata(in: "Staking", storageName: "account"))
    }

    func testFetchFunction() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(try metadata.getFunction(from: "Staking", with: "nominate"))
        XCTAssertNil(try metadata.getFunction(from: "Staking", with: "account"))
    }

    func testFetchModule() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(metadata.getModuleIndex("System"))
        XCTAssertNil(metadata.getModuleIndex("Undefined"))
    }

    func testFetchCallIndex() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

        XCTAssertNotNil(try metadata.getCallIndex(in: "Staking", callName: "bond"))
        XCTAssertNil(try metadata.getCallIndex(in: "System", callName: "bond"))
    }

    // MARK: Private

    private func performRuntimeMetadataTest(filename: String) {
        do {
            guard let url = Bundle(for: type(of: self))
                    .url(forResource: filename, withExtension: "") else {
                XCTFail("Can't find metadata file")
                return
            }

            let hex = try String(contentsOf: url)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let expectedData = try Data(hexString: hex)

            let decoder = try ScaleDecoder(data: expectedData)
            let encoder = ScaleEncoder()

            let runtimeMetadata = try RuntimeMetadata(scaleDecoder: decoder)

            try runtimeMetadata.encode(scaleEncoder: encoder)
            let resultData = encoder.encode()

            XCTAssertEqual(decoder.remained, 0)
            XCTAssertEqual(expectedData, resultData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

class RuntimeV14MetadataTests: XCTestCase {
    
    func testWestendRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "westend-v14-metadata")
    }

    func testKusamaRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "kusama-v14-metadata")
    }

    func testPolkadotRuntimeMetadata() {
        performRuntimeMetadataTest(filename: "polkadot-v14-metadata")
    }

    func testFetchStorage() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-v14-metadata")

        XCTAssertNotNil(metadata.getStorageMetadata(in: "System", storageName: "Account"))
        XCTAssertNil(metadata.getStorageMetadata(in: "System", storageName: "account"))
    }

    func testFetchConstant() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-v14-metadata")

        XCTAssertNotNil(metadata.getConstant(in: "Staking", constantName: "SlashDeferDuration"))
        XCTAssertNil(metadata.getStorageMetadata(in: "Staking", storageName: "account"))
    }

    func testFetchFunction() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-v14-metadata")

        XCTAssertNotNil(try metadata.getFunction(from: "Staking", with: "nominate"))
        XCTAssertNil(try metadata.getFunction(from: "Staking", with: "account"))
    }

    func testFetchModule() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-v14-metadata")

        XCTAssertNotNil(metadata.getModuleIndex("System"))
        XCTAssertNil(metadata.getModuleIndex("Undefined"))
    }

    func testFetchCallIndex() throws {
        let metadata = try RuntimeHelper.createRuntimeMetadata("westend-v14-metadata")

        XCTAssertNotNil(try metadata.getCallIndex(in: "Staking", callName: "bond"))
        XCTAssertNil(try metadata.getCallIndex(in: "System", callName: "bond"))
    }

    // MARK: Private

    private func performRuntimeMetadataTest(filename: String) {
        do {
            guard let url = Bundle(for: type(of: self))
                    .url(forResource: filename, withExtension: "") else {
                XCTFail("Can't find metadata file")
                return
            }

            let hex = try String(contentsOf: url)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let expectedData = try Data(hexString: hex)

            let decoder = try ScaleDecoder(data: expectedData)
            let encoder = ScaleEncoder()

            let runtimeMetadata = try RuntimeMetadata(scaleDecoder: decoder)

            try runtimeMetadata.encode(scaleEncoder: encoder)
            let resultData = encoder.encode()

            XCTAssertEqual(decoder.remained, 0)
            XCTAssertEqual(expectedData, resultData)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
