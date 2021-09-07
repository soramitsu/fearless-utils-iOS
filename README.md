
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

### Crypto    
#### SeedFactory
SeedFactory is responsible for creation of seed from a mnemonic and can either generate a random mnemonic-seed pair or derive seed from existing mnemonic words:
```swift
public protocol SeedFactoryProtocol {
    func createSeed(from password: String, strength: IRMnemonicStrength) throws -> SeedFactoryResult
    func deriveSeed(from mnemonicWords: String, password: String) throws -> SeedFactoryResult
}
```

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
Keypair generation:
BIP32KeypairFactory // BIP32
	Example
EcdsaKeypairFactory // (BTC/ETH compatible)
Example
Ed25519KeypairFactory // Edwards (alternative)
	Example
SR25519KeypairFactory // Schnorrkel 
Example

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


### QR


### Common

  
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
