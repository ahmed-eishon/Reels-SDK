Pod::Spec.new do |spec|
  spec.name                  = 'ReelsIOS'
  spec.version               = '1.0.0'
  spec.summary               = 'Native iOS bridge for ReelsSDK Flutter module'
  spec.description           = <<-DESC
    ReelsIOS provides native iOS bridge classes for ReelsSDK Flutter module.
    It includes Swift APIs for initializing and controlling Flutter reels functionality.
  DESC

  spec.homepage              = 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk'
  spec.license               = { :type => 'Proprietary', :text => 'Copyright Rakuten' }
  spec.author                = { 'Rakuten ROOM Team' => 'room-team@rakuten.com' }

  spec.source                = { :path => '.' }

  spec.ios.deployment_target = '16.0'
  spec.swift_version         = '5.9'

  # Swift bridge source files
  spec.source_files          = 'Sources/ReelsIOS/**/*.swift'

  # Flutter dependency
  spec.dependency 'Flutter'
end
