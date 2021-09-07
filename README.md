
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

## Documentation (each item leads to a separate file in Wiki)
-   Runtime
-   Scale
-   Extrinsic
-   Network
-   Crypto    
-   Keystore
-   Icon
-   QR
-   Common
-   Full documentation
  
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
