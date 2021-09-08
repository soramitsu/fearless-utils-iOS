
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

## Documentation
### Runtime
### Scale
### Extrinsic
### Network
WebSocketEngine description, sequence diagram demonstrating communication schema

Initialization
```swift
// store reference to WebSocketEngine
private(set) var engine: WebSocketEngine?

...

let url = URL.init(string: "...")
let reachabilityManager = ReachabilityManager.shared
let reconnectionStrategy = ExponentialReconnection()
let version = "2.0"
let processingQueue = DispatchQueue(label: "...")
let autoconnect = true
let connectionTimeout = 10.0
let pingInterval = 30
let logger = Logger.shared

let engine = WebSocketEngine(
    url: url,
    reachabilityManager: reachabilityManager,
    reconnectionStrategy: reconnectionStrategy,
    version: version,
    processingQueue: processingQueue,
    autoconnect: autoconnect,
    connectionTimeout: timeInterval,
    pingInterval: pingInterval,
    logger: logger
)

// delegate is needed to process events from the engine
engine.delegate = self
self.engine = engine
```

To process connection state changes from an engine, it is necessary to implement `WebSocketEngineDelegate` protocol:
```swift
protocol WebSocketEngineDelegate: AnyObject {
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


### Icon
One of the features of Polkadot UI is a special icon, generated from public key data. Currently, there is TypeScript implementation and we just re-implemented it for iOS. Generally, it just packs smaller circles inside the hexagon inscribed into an outer circle with a radius of 32 points. Colors to fill small circles are chosen based on binary representation of the public key.

Usage:
```swift
let iconGenerator = PolkadotIconGenerator()
let address = "5Dqvi1p4C7EhPPFKCixpF3QiaJEaDwWrR9gfWR5eUsfC39TX"
let icon = try? iconGenerator.generateFromAddress(account.address)
```

Icons example:

<img src="https://user-images.githubusercontent.com/3176149/132311408-c8e02e33-eb51-4f35-bdde-76b72ba07333.png" height="50">

### QR
QR is one of the most common ways to pass wallet addresses and public keys from person to person. To create or read QR-codes you will need to create an instance of SubstrateQREncoder or SubstrateQRDecoder and call corresponding functions.

#### Encoding
```swift
let substrateEncoder = SubstrateQREncoder()

let info = SubstrateQRInfo(
            address: address,
            rawPublicKey: publicKey,
            username: username
        )

let result = try? substrateEncoder.encode(info: info)
```

#### Decoding
```swift
let substrateDecoder = SubstrateQRDecoder(chainType: 2) // Kusama network

let info = try substrateDecoder.decode(data: data)
let address = info.address
```

#### Additional info
Following is the format of a QR that is used for transfers:

`<prefix>:<address>:<public_key in hex>:<name>`, where **prefix** = "substrate"

Example:

`substrate:FiLhWLARS32oxm4s64gmEMSppAdugsvaAx1pCjweTLGn5Rf:0x8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931:Russel`


### Common
#### BigInt+CurveOrder 
(it’s better to refactor it out, since it is used locally in one place and most probably not going to be needed by anyone)

#### ChainType
An alias for UInt16 data type

#### CryptoType
An enum representing options for supported cryptographic algorithms

#### Data extensions
**Data+AccountId**: helper functions to work with AccountId’s

```swift
// Checks if data supposed to be a public key matches data supposed to be a corresponding account ID
func matchPublicKeyToAccountId(_ accountId: Data) -> Bool

// Converts public key data to account ID data
func publicKeyToAccountId() throws -> Data
```

**Data+FixedWidthInteger**: serializes data as a fixed length integer applying big-endian or little-endian byte order

```swift
func scanValue<T: FixedWidthInteger>(
        at index: Data.Index,
        endianness: Endianness
    ) -> T
```

**Data+Hash**: a set of hashing functions (BLAKE, BLAKE2, xxHash)

```swift
// Concatenates result of blake2b16() with an original data
func blake128Concat() throws -> Data

// Generates BLAKE2b hash with digest size of 16 bytes
func blake2b16() throws -> Data 

// Generates BLAKE2b hash with digest size of 32 bytes
func blake2b32() throws -> Data 

// Generates 64-bit XXH64 hash and returns it concatenated it with an original data
func twox64Concat() -> Data

// Generates 128-bit XXH64 hash 
func twox128() -> Data

// Generates 256-bit XXH64 hash 
func twox256() -> Data
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

**Scheduler**: notifies its delegate after a set period of time.
```swift
protocol SchedulerProtocol: AnyObject {
    func notifyAfter(_ seconds: TimeInterval)
    func cancel()
}

protocol SchedulerDelegate: AnyObject {
    func didTrigger(scheduler: SchedulerProtocol)
}
```

Usage: 
```swift
let delegate = ...
let scheduler = Scheduler(with: delegate)

scheduler.notifyAfter(delay)
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

**UIColor+HSL**: `colorWithHSL` function creates an UIColor object from provided hue/saturation/lightness values
```swift
func colorWithHSL(hue: CGFloat, saturation: CGFloat, lightness: CGFloat) -> UIColor
```

Full documentation[ios-substrate-sdk]

## Unit Tests
ios-substrate-sdk includes a set of unit tests within the Tests subdirectory. These tests can be run from an example project.

## Communication
If you need help, ...

If you'd like to ask a general question, ...

If you found a bug, open an issue in this repo and follow the guide. Be sure to provide necessary detail to reproduce it.

If you have a feature request, open an issue.

If you want to contribute, submit a pull request.

## Author
ERussel, emkil.russel@gmail.com

## License
ios-substrate-sdk is available under the MIT license. See the LICENSE file for more info.
