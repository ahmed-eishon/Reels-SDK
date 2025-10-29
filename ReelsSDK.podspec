Pod::Spec.new do |spec|
  spec.name                  = 'ReelsSDK'
  spec.version               = File.read(File.join(__dir__, 'VERSION')).strip
  spec.summary               = 'Video reels SDK for iOS with Flutter integration'
  spec.description           = <<-DESC
    ReelsSDK provides a Flutter-based video reels experience for iOS applications.
    Features include video playback, engagement buttons (like, share), analytics tracking,
    and type-safe platform communication using Pigeon.
  DESC

  spec.homepage              = 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk'
  spec.license               = { :type => 'Proprietary', :text => 'Copyright Rakuten' }
  spec.author                = { 'Rakuten ROOM Team' => 'room-team@rakuten.com' }

  spec.source                = {
    :git => 'https://gitpub.rakuten-it.com/scm/~ahmed.eishon/reels-sdk.git',
    :tag => "v#{spec.version}"
  }

  spec.ios.deployment_target = '16.0'
  spec.swift_version         = '5.9'

  # Swift bridge source files
  spec.source_files          = 'reels_ios/Sources/ReelsIOS/**/*.swift'

  # Flutter module integration
  flutter_application_path = 'reels_flutter'

  # Load Flutter's podhelper if available (for Add-to-App)
  podhelper_path = File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

  if File.exist?(podhelper_path)
    # Standard Flutter Add-to-App integration
    eval(File.read(podhelper_path), binding)
    install_all_flutter_pods(flutter_application_path)
  else
    # Fallback: Manual Flutter framework dependency
    spec.dependency 'Flutter'

    # Include Flutter module as a resource
    spec.preserve_paths = "#{flutter_application_path}/**/*"
  end

  # Exclude build artifacts and cache
  spec.exclude_files = [
    "#{flutter_application_path}/.dart_tool/**/*",
    "#{flutter_application_path}/build/**/*",
    "#{flutter_application_path}/.ios/**/*",
    "#{flutter_application_path}/.android/**/*"
  ]
end
