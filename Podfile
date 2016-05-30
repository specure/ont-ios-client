use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!

abstract_target 'All' do

  # use latest version of CocoaAsyncSocket because of manual trusting
  #pod 'CocoaAsyncSocket', '~> 7.4.2'
  pod 'CocoaAsyncSocket', :git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git'

  # swift pods
  pod 'XCGLogger', '~> 3.3'
  #pod 'BrightFutures', '~> 1.0.0'

  target 'RMBTClient_iOS' do
    platform :ios, '8.4'

    # Pods for RMBTClient_iOS
    pod 'AFNetworking', '~> 2.5.4' #'~> 2.6.3' # '~> 3.0.4' # maybe later replace with Alomofire
    pod 'BlocksKit', '~> 2.2.5'
    pod 'GCNetworkReachability', '~> 1.3.2'
  end

  target 'RMBTClient_OSX' do
    platform :osx, '10.9'

    # Pods for RMBTClient_OSX
    pod 'AFNetworking', '~> 2.5.4' #'~> 2.6.3' # '~> 3.0.4' # maybe later replace with Alomofire
    pod 'BlocksKit', '~> 2.2.5'
    pod 'GCNetworkReachability', '~> 1.3.2'
  end

  target 'RMBTClient_tvOS' do
    platform :tvos, '9.2'

    # Pods for RMBTClient_tvOS
    # TODO: afnetworking doesn't support tvos (in the version we us...) -> have to update or use alamofire?
    # TODO: same for blockskit and GCNetworkReachability
  end
end

