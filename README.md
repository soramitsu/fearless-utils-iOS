
# ios-substrate-sdk
[![CI Status](https://img.shields.io/travis/ERussel/FearlessUtils.svg?style=flat)](https://travis-ci.org/ERussel/FearlessUtils)
[![Version](https://img.shields.io/cocoapods/v/FearlessUtils.svg?style=flat)](https://cocoapods.org/pods/FearlessUtils)
[![License](https://img.shields.io/cocoapods/l/FearlessUtils.svg?style=flat)](https://cocoapods.org/pods/FearlessUtils)
[![Platform](https://img.shields.io/cocoapods/p/FearlessUtils.svg?style=flat)](https://cocoapods.org/pods/FearlessUtils)

ios-substrate-sdk is a native iOS framework created to help developers build native mobile apps for Substrate-based networks such as Polkadot, Kusama, and Westend.

To develop blockchain-related applications with rich functionality one would need to have a toolset that provided means to exchange data with the network along with utility tools, such as cryptography. There was no such toolset when we needed it, so we decided to create it ourselves. Now it offers enough functionality to maintain connection to a node, prepare and send requests and process responses, work with mnemonics and generate keys, decode and encode QR codes, even create Polkadot Icons!

Maintenance & development is funded by Kusama Treasury.

## Features
- SCALE encoding/decoding
- Network communication: a set of higher-level functions for interaction with a node using web sockets
- Seed from mnemonic generation
- Keypair generation/derivation for Substrate- and Ethereum-based networks
- Substrate QR encoding/decoding
- Polkadot icon generation

## Requirements
Platform: iOS 11.0+

Swift version: 5.0+

Installation: Cocoapods

## Installation
ios-substrate-sdk is available through [CocoaPods](https://cocoapods.org/). For usage and installation instructions first check out **Get Started** section on their website.

To add ios-substrate-sdk to your project simply add the following line to your Podfile:
```ruby
pod 'ios-substrate-sdk'
```

Then run
```
pod install
```
## Example
We provide a simple example that demonstrates how to use one of the SDK capabilities — Polkadot icon generation. To run the example project, clone the repo, and run `pod install` from the Example directory.

## Architecture
Following firure represents very high-level view on library architecture. Basically, it displays components distribution by module and dependency from `IrohaCrypto` library.

<img src="https://user-images.githubusercontent.com/3176149/132594685-62c01bf8-2bc3-4858-b8e9-0ba24f682128.png" width="800">


## Documentation
### Runtime
The idea of a Runtime is to share single runtime code between network nodes to execute. The runtime code implements node’s main logic, for example, consensus or data processing and can be upgraded without stopping the network. Runtime code consists of several modules called _pallets_ which implement some specific logic: consensus, asset management etc. So, different networks can have different pallets included to runtime code. It must be taken into account when a user switches between networks in a mobile application. Runtime exposes API that can be used to execute functions of included pallets.


In library, the main class reflecting runtime is `RuntimeMetadata`:
```swift
public struct RuntimeMetadata {
    public let metaReserved: UInt32
    public let runtimeMetadataVersion: UInt8
    public let modules: [ModuleMetadata]
    public let extrinsic: ExtrinsicMetadata

    public init(metaReserved: UInt32,
                runtimeMetadataVersion: UInt8,
                modules: [ModuleMetadata],
                extrinsic: ExtrinsicMetadata) {
        self.modules = modules
        self.extrinsic = extrinsic
        self.metaReserved = metaReserved
        self.runtimeMetadataVersion = runtimeMetadataVersion
    }
    ...
}
```

This struct and all the internal structures conform to `ScaleCodable` protocol. To obtain metadata for storage, constants, functions etc. you'll need to call corresponding functions:
```swift
let metadata = try RuntimeHelper.createRuntimeMetadata("westend-metadata")

// Storage
let storageMetadata = metadata.getStorageMetadata(in: "System", storageName: "Account")
// Constant
let constant = metadata.getConstant(in: "Staking", constantName: "SlashDeferDuration")
// Function
let function = metadata.getFunction(from: "Staking", with: "nominate")
// Module
let moduleIndex = metadata.getModuleIndex("System")
// Call
let callIndex = metadata.getCallIndex(in: "Staking", callName: "bond")
```

### Scale
SCALE encoding is a lightweight serialization for arbitrary data structures. We implemented this algorithm in our library to be able to send and receive such structures via JSON RPC calls. Implementation satisfies [Runtime](https://substrate.dev/docs/en/knowledgebase/runtime/) and [SCALE](https://substrate.dev/docs/en/knowledgebase/advanced/codec) specs published on Substrate Developer Hub.

#### Standart Data Types
Library provides the support for the following data types:

`Bool?`

`Int8`, `Int16`, `Int32`, `Int64`

`UInt8`, `UInt16`, `UInt32`, `UInt64`

`BigUInt`

`Array`, `Tuple`, `Result`, `Optional`

`String`

`Data`


#### Define a schema
```swift
struct AccountInfo: Codable, Equatable {
    @StringCodable var nonce: UInt32
    @StringCodable var consumers: UInt32
    @StringCodable var providers: UInt32
    let data: AccountData
}

struct AccountData: Codable, Equatable {
    @StringCodable var free: BigUInt
    @StringCodable var reserved: BigUInt
    @StringCodable var miscFrozen: BigUInt
    @StringCodable var feeFrozen: BigUInt
}
```

#### Optional properties

There is a special property wrapper `@OptionStringCodable` to work with optional properties:
```swift
public struct ExtrinsicSignedExtra: Codable {
    enum CodingKeys: String, CodingKey {
        case era
        case nonce
        case tip
    }

    public var era: Era?
    @OptionStringCodable public  var nonce: UInt32?
    @OptionStringCodable public  var tip: BigUInt?

    public init(era: Era?, nonce: UInt32?, tip: BigUInt?) {
        self.era = era
        self.nonce = nonce
        self.tip = tip
    }
}
```

You can use `@NullCodable` property wrapper to work with optional properties of complex types:
```swift
struct CrowdloanContributeCall: Codable {
    @StringCodable var index: ParaId
    @StringCodable var value: BigUInt
    @NullCodable var signature: MultiSignature?
}
```

#### Encoding and decoding
```swift
do {
    let optional = ScaleOption.some(value: "Kusama")))

    let encoder = ScaleEncoder()
    try optional.encode(scaleEncoder: encoder)

    let decoder = try ScaleDecoder(data: encoder.encode())
    let newOptional = try ScaleOption<T>(scaleDecoder: decoder)
} catch { 
    ...
}
```
    

### Extrinsic

An extrinsic builder is a convenient tool to form extrinsics by setting up necessary parameters. It implements `ExtrinsicBuilderProtocol`:
```swift
public protocol ExtrinsicBuilderProtocol: AnyObject {
    func with<A: Codable>(address: A) throws -> Self
    func with(nonce: UInt32) -> Self
    func with(era: Era, blockHash: String) -> Self
    func with(tip: BigUInt) -> Self
    func with(shouldUseAtomicBatch: Bool) -> Self
    func adding<T: RuntimeCallable>(call: T) throws -> Self

    func signing(by signer: (Data) throws -> Data,
                 of type: CryptoType,
                 using encoder: DynamicScaleEncoding,
                 metadata: RuntimeMetadata) throws -> Self

    func build(encodingBy encoder: DynamicScaleEncoding, metadata: RuntimeMetadata) throws -> Data
}
```

This is how to use it to create an extrinsic building closure for **transfer** call:
```swift
private func createExtrinsicBuilderClosure(amount: BigUInt) -> ExtrinsicBuilderClosure {
    let closure: ExtrinsicBuilderClosure = { builder in
        let args = TransferCall(to: accountId, amount: amount)
        let call = RuntimeCall(moduleName: "Balances", callName: "transfer", args: args)

        _ = try builder.adding(call: call)
        return builder
    }

    return closure
}
```

### Network
Library provides an implementation of web socket engine, which simplifies communication with the node: it provides a subscription mechanism with error recovery.

#### Initialization
To start an engine, you need to define several parameters:
```swift
// store reference to WebSocketEngine
private(set) let engine: WebSocketEngine?

...

let url = URL.init(string: "...")
let reachabilityManager = ReachabilityManager.shared
let reconnectionStrategy = ExponentialReconnection()
let version = "2.0"
let processingQueue = DispatchQueue(label: "...")
let autoconnect = true
let connectionTimeout = 10.0
let pingInterval = 30

let engine = WebSocketEngine(
    url: url,
    reachabilityManager: reachabilityManager,
    reconnectionStrategy: reconnectionStrategy,
    version: version,
    processingQueue: processingQueue,
    autoconnect: autoconnect,
    connectionTimeout: timeInterval,
    pingInterval: pingInterval
)

// delegate is needed to process events from the engine
engine.delegate = self
self.engine = engine
```

To process connection state changes from an engine, it is necessary to implement `WebSocketEngineDelegate` protocol:
```swift
public protocol WebSocketEngineDelegate: AnyObject {
    func webSocketDidChangeState(
        from oldState: WebSocketEngine.State,
        to newState: WebSocketEngine.State
    )
}
```

An example implementation could look like this:
```swift
func webSocketDidChangeState(
    from _: WebSocketEngine.State,
    to newState: WebSocketEngine.State
) {
    switch newState {
    case let .connecting(attempt):
        if attempt > 1 {
            // What to do when network becomes unreachable
            scheduleNetworkUnreachable()
        }
    case .connected:
        // What to do when network becomes reachable
        scheduleNetworkReachable()
    default:
        break
    }
}
```

#### Reachability
An application should track network reachability status and react accordingly. There are two functions: `connectIfNeeded` and `disconnectIfNeeded` that check connection state and do all the necessary work:
```swift
func didReceiveDidBecomeActive(notification _: Notification) {
    if !isActive {
        isActive = true
        engine?.connectIfNeeded()
    }
}

func didReceiveDidEnterBackground(notification _: Notification) {
    if isActive {
        isActive = false
        engine?.disconnectIfNeeded()
    }
}
```

`ios-substrate-sdk` provides reachability manager as well. It allows to check reachability state manually or add a delegate that would process reachability changes:
```swift
public protocol ReachabilityListenerDelegate: AnyObject {
    func didChangeReachability(by manager: ReachabilityManagerProtocol)
}

public protocol ReachabilityManagerProtocol {
    var isReachable: Bool { get }

    func add(listener: ReachabilityListenerDelegate) throws
    func remove(listener: ReachabilityListenerDelegate)
}
```

Usage:
```swift
func subscribeToReachabilityStatus() {
    do {
        try reachabilityManager?.add(listener: self)
    } catch {
        print("Failed to subscribe to reachability changes")
    }
}

func clearReachabilitySubscription() {
    reachabilityManager?.remove(listener: self)
}
 
func didChangeReachability(by manager: ReachabilityManagerProtocol) {
    // Process changes here
}
```

#### Reconnection strategy
Default reconnection strategy is `ExponentialReconnection`. However, you can implement any strategy you need by implementing `ReconnectionStrategyProtocol`:
```swift
public protocol ReconnectionStrategyProtocol {
    func reconnectAfter(attempt: Int) -> TimeInterval?
}

struct LinearReconnection: ReconnectionStrategyProtocol {
    public func reconnectAfter(attempt: Int) -> TimeInterval? {
        Double(attempt)
    }
}

```

### Crypto    
#### SeedFactory
SeedFactory is responsible for creation of seed from a mnemonic and can either generate a random mnemonic-seed pair or derive seed from existing mnemonic words:
```swift
public typealias SeedFactoryResult = (seed: Data, mnemonic: IRMnemonicProtocol)

public protocol SeedFactoryProtocol {
    func createSeed(from password: String, strength: IRMnemonicStrength) throws -> SeedFactoryResult
    func deriveSeed(from mnemonicWords: String, password: String) throws -> SeedFactoryResult
}
```

Note: BIP39 support is implemented in `IrohaCrypto` library, so if you want to get it out of the box, you'll need to install it the same way as `ios-substrate-sdk` and then import necessary modules.

Usage:
```swift
let password = ""
let strength: IRMnemonicStrength = .entropy256

let expectedResult = try seedFactory.createSeed(from: password, strength: strength)

let mnemonicWords = expectedResult.mnemonic.toString()

let derivedResult = try seedFactory.deriveSeed
(
    from: mnemonicWords,
    password: password
)
```

Note: there are two types of seed factory that conform to SeedFactoryProtocol but differ in internal implementation:
`SeedFactory` used for substrate-based networks key generation
`BIP32SeedFactory` used for BIP32 keys derivation

#### Junction factory
A junction factory converts text representation of a derivation path into a list of components: hard and soft junctions and a password. Input format is /soft//hard///password for Substrate-based networks and /0//0///password for BIP32. It has only one function defined by `JunctionFactoryProtocol`:

```swift
public protocol JunctionFactoryProtocol {
    func parse(path: String) throws -> JunctionResult
}
```

It returns a following structure:
```swift
public struct JunctionResult {
    public let chaincodes: [Chaincode]
    public let password: String?
}
```

Example:
```swift
let derivationPath = ...
let junctionFactory = JunctionFactory()
junctionResult = try junctionFactory.parse(path: derivationPath)
```

Note: there are two types of junction factory that conform to `JunctionFactoryProtocol` but differ in internal implementation:
`SubstrateJunctionFactory` is used for parsing substrate-based networks derivation paths
`BIP32JunctionFactory` is used for parsing BIP32 derivation paths

#### Keypair factory
The library support keypair generation using the following algorithms:
* Sr25519 (`SR25519KeypairFactory`)
* Ed25519 (`Ed25519KeypairFactory`)
* ECDSA (`EcdsaKeypairFactory`)
* BIP32 (`BIP32KeypairFactory`)

Each algorithm is implemented as a Factory conforming to one of the following protocols, meaning that in any case you can create a keypair from a seed and in some cases you can derive a child keypair from a parent one:
```swift
public protocol KeypairFactoryProtocol {
    func createKeypairFromSeed(_ seed: Data, chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol
}

public protocol DerivableKeypairFactoryProtocol: KeypairFactoryProtocol {
    func deriveChildKeypairFromParent(_ keypair: IRCryptoKeypairProtocol,
                                      chaincodeList: [Chaincode]) throws -> IRCryptoKeypairProtocol
}
```

`EcdsaKeypairFactory` and `Ed25519KeypairFactory` also conform to `DerivableSeedFactoryProtocol` so you can derive child seed from a parent seed
```swift
public protocol DerivableSeedFactoryProtocol: KeypairFactoryProtocol {
    func deriveChildSeedFromParent(_ seed: Data,
                                   chaincodeList: [Chaincode]) throws -> Data
}
```

All components usage example:
```swift
let junctionFactory = SubstrateJunctionFactory()
let seedFactory = SeedFactory()
let keypairFactory = SR25519KeypairFactory()

let path = "//foo/bar"
let mnemonic = "bottom drive obey lake curtain smoke basket hold race lonely fit walk"

let junctionResult = try junctionFactory.parse(path: path)

let seedResult = try seedFactory.deriveSeed(
    from: mnemonic,
    password: junctionResult.password ?? "")

let keypair = try keypairFactory.createKeypairFromSeed(
    seedResult.seed.miniSeed,
    chaincodeList: junctionResult.chaincodes
)

let publicKey = keypair.publicKey().rawData()
let privateKey = keypair.privateKey().rawData()
```

### Keystore
This module is intended to bring account import and export capabilities. Two main parts are `KeystoreBuilder` and `KeystoreExtractor`. 

To create export JSON we use `KeystoreBuilder` as follows:
```swift
func export(account: AccountItem, password: String?) throws -> Data {
    guard let secretKey = try keystore.fetchSecretKeyForAddress(account.address) else {
        throw KeystoreExportWrapperError.missingSecretKey
    }

    let addressType = try ss58Factory.type(fromAddress: account.address)

    var builder = KeystoreBuilder()
        .with(name: account.username)

    if let genesisHash = SNAddressType(rawValue: addressType.uint8Value)?.chain.genesisHash,
       let genesisHashData = try? Data(hexString: genesisHash) {
        builder = builder.with(genesisHash: genesisHashData.toHex(includePrefix: true))
    }

    let keystoreData = KeystoreData(
        address: account.address,
        secretKeyData: secretKey,
        publicKeyData: account.publicKeyData,
        cryptoType: account.cryptoType.utilsType
    )

    let definition = try builder.build(from: keystoreData, password: password)

    return try jsonEncoder.encode(definition)
}
```

To import it back, we use `KeystoreExtractor`:
```swift
func extractKeystoreData(request: AccountImportKeystoreRequest) {
    let keystoreExtractor = KeystoreExtractor()

    guard let data = request.keystore.data(using: .utf8) else {
        throw AccountOperationFactoryError.invalidKeystore
    }

    let keystoreDefinition = try JSONDecoder().decode(
        KeystoreDefinition.self,
        from: data
    )

    guard let keystore = try? keystoreExtractor
        .extractFromDefinition(keystoreDefinition, password: request.password)
    else {
        throw AccountOperationFactoryError.decryption
    }

    ...
        
}
```

### Icon
One of the features of Polkadot UI is a special icon, generated from public key data. Currently, there is [TypeScript implementation](https://github.com/polkadot-js/ui/blob/master/packages/ui-shared/src/icons/polkadot.ts) and we just re-implemented it for iOS. Generally, it just packs smaller circles inside the hexagon inscribed into an outer circle with a radius of 32 points. Colors to fill small circles are chosen based on binary representation of the public key.

Usage:
```swift
let iconGenerator = PolkadotIconGenerator()
let address = "5Dqvi1p4C7EhPPFKCixpF3QiaJEaDwWrR9gfWR5eUsfC39TX"
let icon = try? iconGenerator.generateFromAddress(address)
```

Icons example:

<img src="https://user-images.githubusercontent.com/3176149/132311408-c8e02e33-eb51-4f35-bdde-76b72ba07333.png" height="50">

### QR
QR is one of the most common ways to pass wallet addresses and public keys from person to person. To create or read QR-codes you will need to create an instance of SubstrateQREncoder or SubstrateQRDecoder and call corresponding functions.

#### Encoding
```swift
let substrateEncoder = SubstrateQREncoder()

let info = SubstrateQRInfo
(
    address: address,
    rawPublicKey: publicKey,
    username: username
)

let result = try? substrateEncoder.encode(info: info)
```

#### Decoding
```swift
let substrateDecoder = SubstrateQRDecoder(chainType: 2) // Kusama network

let info = try? substrateDecoder.decode(data: data)
let address = info.address
```

#### Additional info
Following is the format of a QR that is used for transfers:

`<prefix>:<address>:<public_key in hex>:<name>`, where **prefix** = "substrate"

Example:

`substrate:FiLhWLARS32oxm4s64gmEMSppAdugsvaAx1pCjweTLGn5Rf:0x8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931:Russel`


### Common
#### Data extensions
**Data+AccountId**: helper functions to work with AccountId’s

```swift
public extension Data {
    // Checks if data supposed to be a public key matches data supposed to be a corresponding account ID
    func matchPublicKeyToAccountId(_ accountId: Data) -> Bool { ... }

    // Converts public key data to account ID data
    func publicKeyToAccountId() throws -> Data { ... }
}
```

**Data+Hash**: a set of hashing functions (BLAKE, BLAKE2, xxHash)

```swift
public extension Data {
    // Concatenates result of blake2b16() with an original data
    func blake128Concat() throws -> Data { ... }

    // Generates BLAKE2b hash with digest size of 16 bytes
    func blake2b16() throws -> Data { ... }

    // Generates BLAKE2b hash with digest size of 32 bytes
    func blake2b32() throws -> Data { ... }

    // Generates 64-bit XXH64 hash and returns it concatenated it with an original data
    func twox64Concat() -> Data { ... }

    // Generates 128-bit XXH64 hash 
    func twox128() -> Data { ... }

    // Generates 256-bit XXH64 hash 
    func twox256() -> Data { ... }
}
```

**Data+Hex**: easy-to-use Hex - Data - Hex converter
```swift
// Hex string to Data
init(hexString: String) throws

// Data to Hex string
func toHex(includePrefix: Bool = false) -> String
```

**Data+Random**: random data generator
```swift
static func generateRandomBytes(of length: Int) throws -> Data
```

**Decimal+Substrate**: provides a set of functions for Decimal - BigUInt - Decimal conversion
```swift
// Decimal from BigUInt with precision passed as a parameter
static func fromSubstrateAmount(_ value: BigUInt, precision: Int16) -> Decimal?

// Decimal from BigUInt with preset precision (read about Substrate precisions)
static func fromSubstratePerbill(value: BigUInt) -> Decimal?

// BigUInt from Decimal with precision passed as a parameter
func toSubstrateAmount(precision: Int16) -> BigUInt?
```

**JSON**: provides support for decoding/encoding account information using JSON format, compatible with Substrate networks

**SDKLogger**: presents protocol that has to be implemented in order to provide optional logger instance to WebSocketEngine
```swift
public protocol SDKLoggerProtocol {
    func verbose(message: String, file: String, function: String, line: Int)
    func debug(message: String, file: String, function: String, line: Int)
    func info(message: String, file: String, function: String, line: Int)
    func warning(message: String, file: String, function: String, line: Int)
    func error(message: String, file: String, function: String, line: Int)
}
```

**StorageKeyFactory**: creates simple, hashed or double-hashed storage key from a module name and a storage name.
```swift
public protocol StorageKeyFactoryProtocol: AnyObject {
    func createStorageKey(moduleName: String, storageName: String) throws -> Data

    func createStorageKey(moduleName: String,
                          storageName: String,
                          key: Data,
                          hasher: StorageHasher) throws -> Data

    func createStorageKey(moduleName: String,
                          storageName: String,
                          key1: Data,
                          hasher1: StorageHasher,
                          key2: Data,
                          hasher2: StorageHasher) throws -> Data
}
```

Usage:
```swift
let factory = StorageKeyFactory()

let key = try Data(hexString: "8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

let storageKey = try factory.createStorageKey(moduleName: "System",
                                               storageName: "Account",
                                               key: key,
                                               hasher: .blake128Concat)
```

## Unit Tests
ios-substrate-sdk includes a set of unit tests within the Tests subdirectory. These tests can be run from an example project.

## Communication
If you need help or you'd like to ask a general question, join the [Fearless Wallet Telegram group](t.me/fearlesswallet).

If you found a bug, open an issue in this repo and follow the guide. Be sure to provide necessary detail to reproduce it.

If you have a feature request, open an issue.

If you want to contribute, submit a pull request.

## Author
ERussel, emkil.russel@gmail.com

## License
ios-substrate-sdk is available under the MIT license. See the LICENSE file for more info.
