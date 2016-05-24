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

  s.description = 'RMBTClient supports ...'

  s.default_subspec = 'All'

  s.requires_arc = true

  s.ios.deployment_target = '8.4'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.9'
end