Pod::Spec.new do |s|
  s.name     = 'RMBTClient'
  s.version  = '0.0.1'
  s.license  = { :type => 'apache v2 todo', :text => <<-LICENSE
TODO: APACHE LICENSE v2
                 LICENSE
               }
  s.summary  = 'RMBTClient library for Mac, iOS and tvOS.'
  s.homepage = 'https://github.com/specure/...'
  s.authors  = { 'Benjamin Pucher' => 'benjamin.pucher@specure.com' }

  s.source   = { :git => 'https://github.com/specure/... .git',
                 :tag => "#{s.version}" }

  s.description = 'RMBTClient supports ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ... ...'

#s.default_subspec = 'All'

s.source_files = 'Sources/**/*.swift', 'Sources/RMBTTrafficCounter.h', 'Sources/RMBTRAMMonitor.h', 'Sources/RMBTCPUMonitor.h', 'Sources/GetDNSIP.h', 'Sources/NSString+IPAddress.h', 'Sources/PingUtil.h'

#'Sources/*.h'

#'Sources/RMBTClient.h',

  s.dependency 'AFNetworking', '~> 2.5.4'
  s.dependency 'BlocksKit', '~> 2.2.5'
  s.dependency 'GCNetworkReachability', '~> 1.3.2'
  s.dependency 'CocoaAsyncSocket'
  s.dependency 'XCGLogger', '~> 3.3'

  s.requires_arc = true

  s.osx.exclude_files = 'Sources/RMBTHelpers_iOS.swift'

#s.public_header_files = "Sources/RMBTClient.h"

  s.xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/Sources/','LIBRARY_SEARCH_PATHS' => '$(SRCROOT)/Sources/'}
#s.module_map = 'Sources/module.modulemap'
  s.preserve_paths = 'Sources/*.modulemap'


#s.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/Sources/RMBTClientPrivate/**','LIBRARY_SEARCH_PATHS' => '$(SRCROOT)/Sources/RMBTClientPrivate/','MODULEMAP_PRIVATE_FILE' => '$(SRCROOT)/Sources/module.private.modulemap'}
#s.xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/Sources/RMBTClientPrivate/**','LIBRARY_SEARCH_PATHS' => '$(SRCROOT)/Sources/RMBTClientPrivate/'}
#s.preserve_paths = 'Sources/RMBTClientPrivate/module.modulemap'

  #s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '${SRCROOT}/../rmbt-ios-client/RMBTClientPrivate' }
  #s.preserve_paths = 'Sources/RMBTClientPrivate/module.modulemap'
  #s.xcconfig = { 'SWIFT_INCLUDE_PATHS' => '"${SRCROOT}/../rmbt-ios-client/RMBTClientPrivate"' }
  #s.preserve_paths = 'Sources/RMBTClientPrivate'
  #s.module_map = 'Sources/module.modulemap'

  s.ios.deployment_target = '8.4'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
end

