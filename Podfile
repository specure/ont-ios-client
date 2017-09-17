use_frameworks!

# ignore all warnings from all pods
inhibit_all_warnings!
platform :ios, '9.0'

abstract_target 'All' do

  pod 'CocoaAsyncSocket', :git => 'https://github.com/robbiehanson/CocoaAsyncSocket.git' # until >= 7.5.1 is available

  pod 'Alamofire'
  pod 'AlamofireObjectMapper'

  pod 'RealmSwift'

  pod 'XCGLogger'

  target 'RMBTClient_iOS' do
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
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '3.1'
        end
    end
end
