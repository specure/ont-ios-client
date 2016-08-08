use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!

abstract_target 'All' do

  pod 'CocoaAsyncSocket', '~> 7.5.0' #:git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git'

  pod 'Alamofire', '~> 3.4.1'
  pod 'AlamofireObjectMapper', '~> 3.0.2'

  # swift pods
  pod 'XCGLogger', '~> 3.3'
  #pod 'BrightFutures', '~> 1.0.0'

  target 'RMBTClient_iOS' do
    platform :ios, '8.4'

    # Pods for RMBTClient_iOS
    pod 'BlocksKit', '~> 2.2.5'
    pod 'GCNetworkReachability', '~> 1.3.2'
  end

  target 'RMBTClient_OSX' do
    platform :osx, '10.9'

    # Pods for RMBTClient_OSX
    pod 'BlocksKit', '~> 2.2.5'
    pod 'GCNetworkReachability', '~> 1.3.2'
  end

  target 'RMBTClient_tvOS' do
    platform :tvos, '9.2'

    # Pods for RMBTClient_tvOS
    # TODO: blockskit and GCNetworkReachability
  end
end

