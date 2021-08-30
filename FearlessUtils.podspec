#
# Be sure to run `pod lib lint FearlessUtils.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'FearlessUtils'
    s.version          = '0.11.0'
    s.summary          = 'Utility library that implements clients specific logic to interact with substrate based networks'

    s.homepage         = 'https://github.com/soramitsu/fearless-utils-iOS'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'ERussel' => 'rezin@soramitsu.co.jp' }
    s.source           = { :git => 'https://github.com/soramitsu/fearless-utils-iOS.git', :tag => s.version.to_s }
    s.swift_version    = '5.0'

    s.ios.deployment_target = '11.0'

    s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64', 'VALID_ARCHS' => 'x86_64 armv7 arm64'  }

    s.source_files = 'FearlessUtils/Classes/**/*'
    s.dependency 'IrohaCrypto/sr25519', '~> 0.8.0'
    s.dependency 'IrohaCrypto/ed25519', '~> 0.8.0'
    s.dependency 'IrohaCrypto/secp256k1', '~> 0.8.0'
    s.dependency 'IrohaCrypto/Scrypt', '~> 0.8.0'
    s.dependency 'IrohaCrypto/ss58', '~> 0.8.0'
    s.dependency 'ReachabilitySwift', '~> 5.0'
    s.dependency 'RobinHood', '~> 2.6.0'
    s.dependency 'Starscream'
    s.dependency 'TweetNacl', '~> 1.0.0'
    s.dependency 'BigInt', '~> 5.0'
    s.dependency 'xxHash-Swift', '~> 1.0.0'

    # Common (Done)
    s.subspec 'Common' do |cn|
        cn.source_files = 'FearlessUtils/Classes/Common/**/*', 'FearlessUtils/Classes/Runtime/Metadata/StorageHasher.swift'
    end

    # Crypto
    s.subspec 'Crypto' do |cr|
        cr.dependency 'FearlessUtils/Common'
        cr.source_files = 'FearlessUtils/Classes/Crypto/**/*', 'FearlessUtils/Classes/Scale/ScaleCoding.swift', 'FearlessUtils/Classes/Scale/Encodable/*.swift'
    end
    #
    #      # Extrinsic
    #      s.subspec 'Extrinsic' do |ex|
    #          DynamicScaleEncoding, Era (Scale)
    #          RuntimeMetadata (Runtime)
    #          ex.dependency 'FearlessUtils/Common'
    #          ex.source_files = 'FearlessUtils/Classes/Extrinsic/**/*'
    #      end

    # Icon (Done)
    s.subspec 'Icon' do |ic|
        ic.dependency 'FearlessUtils/Common'
        ic.source_files = 'FearlessUtils/Classes/Icon/**/*'
    end

    # Keystore (Done)
    s.subspec 'Keystore' do |ks|
        ks.dependency 'FearlessUtils/Common'
        ks.source_files = 'FearlessUtils/Classes/Keystore/**/*'
    end

    # Network
    #  - ERROR | [iOS] [FearlessUtils/Network] file patterns: The `source_files` pattern did not match any file.
    #      s.subspec 'Network' do |nw|
    ##          nw.dependency 'FearlessUtils/Common'
    #          nw.source_files = 'FearlessUtils/Classes/Network/**/*'
    #      end

    # QR (Done)
    s.subspec 'QR' do |qr|
        qr.dependency 'FearlessUtils/Common'
        qr.source_files = 'FearlessUtils/Classes/QR/**/*'
    end

    # Runtime (Done)
    s.subspec 'Runtime' do |rt|
        rt.dependency 'FearlessUtils/Common'
        rt.source_files = 'FearlessUtils/Classes/Runtime/**/*', 'FearlessUtils/Classes/Scale/**/*',  'FearlessUtils/Classes/Extrinsic/**/*'
    end

    # Scale
#         s.subspec 'Scale' do |sc|
#             #      TypeRegistryCatalogProtocol (Runtime)
#             # BoolNode (Runtime)
#             sc.dependency 'FearlessUtils/Common'
#             sc.source_files = 'FearlessUtils/Classes/Scale/**/*', 'FearlessUtils/Classes/Runtime/TypeRegistryCatalogProtocol.swift', 'FearlessUtils/Classes/Runtime/Nodes/Items/**/*', 'FearlessUtils/Classes/Runtime/Types/**/*'
#         end

    s.test_spec do |ts|
        ts.source_files = 'Tests/**/*.swift'
        ts.resources = ['Tests/**/*.json', 'Tests/**/*-metadata']
    end
end
