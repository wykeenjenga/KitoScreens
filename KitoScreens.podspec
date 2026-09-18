Pod::Spec.new do |s|
  s.name             = 'KitoScreens'
  s.version          = '0.2.0'
  s.summary          = 'Prebuilt SwiftUI screens: sign in, sign up, edit profile, M-Pesa and card checkout.'
  s.description      = <<-DESC
    Production-ready SwiftUI screens composed from KitoFields and KitoButtons. Hand each screen an
    async closure and get validation, animated fields, loading and result states, inline server
    errors and localization for free.
  DESC
  s.homepage         = 'https://github.com/wykeenjenga/KitoScreens'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Wycliff Njenga' => 'wycliffnjenga19@gmail.com' }
  s.source           = { :git => 'https://github.com/wykeenjenga/KitoScreens.git', :tag => s.version.to_s }
  s.social_media_url = 'https://x.com/wycliffnjenga2'

  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '12.0'
  s.tvos.deployment_target = '15.0'
  s.watchos.deployment_target = '8.0'
  s.visionos.deployment_target = '1.0'
  s.swift_versions   = ['5.9']
  s.frameworks       = 'SwiftUI'
  s.source_files     = 'Sources/KitoScreens/**/*.swift'
  s.resource_bundles = { 'KitoScreens' => ['Sources/KitoScreens/Resources/**/*.lproj'] }
  s.dependency 'KitoFields', '>= 1.6', '< 2.0'
  s.dependency 'KitoButtons', '>= 1.7', '< 2.0'
end
