Pod::Spec.new do |s|
  s.name             = 'wifi'
  s.version          = '0.0.1'
  s.summary          = 'WiFi SSID monitoring plugin for FlClash'
  s.description      = <<-DESC
A Flutter plugin for monitoring WiFi SSID changes across platforms.
                       DESC
  s.homepage         = 'https://github.com/chen08209/FlClash'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'FlClash' => 'chen08209@example.com' }

  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
