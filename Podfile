use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!

abstract_target 'All' do

  #pod 'CocoaAsyncSocket', '~> 7.5.1' #:git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git'
  pod 'CocoaAsyncSocket', :git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git' # until 7.5.1 is available

  pod 'Alamofire', '~> 3.5.0'
  pod 'AlamofireObjectMapper', '~> 3.0.2'

  #pod 'RealmSwift', '~> 1.0.2'
  pod 'Realm', :git => 'https://github.com/realm/realm-cocoa.git', submodules: true
  pod 'RealmSwift', :git => 'https://github.com/realm/realm-cocoa.git', submodules: true

  pod 'XCGLogger', '~> 3.3.0'
  #pod 'BrightFutures', '~> 1.0.0'

  target 'RMBTClient_iOS' do
    platform :ios, '8.4'

    # Pods for RMBTClient_iOS
    pod 'GCNetworkReachability', '~> 1.3.2'
  end

  target 'RMBTClient_OSX' do
    platform :osx, '10.9'

    # Pods for RMBTClient_OSX
    pod 'GCNetworkReachability', '~> 1.3.2'
  end

  target 'RMBTClient_tvOS' do
    platform :tvos, '9.2'

    # Pods for RMBTClient_tvOS
    # TODO: GCNetworkReachability
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['SWIFT_VERSION'] = "2.3"
    end
  end
end
