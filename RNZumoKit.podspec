

Pod::Spec.new do |s|
  s.name         = "RNZumoKit"
  s.version      = "1.6.0-beta.13"
  s.summary      = "RNZumoKit"
  s.description  = <<-DESC
                  RNZumoKit
                   DESC
  s.homepage     = "https://github.com/dlabs/zumokit-react-native"
  s.license      = "MIT"
  s.author       = { "author" => "Zumo" }
  s.platform     = :ios
  s.ios.deployment_target = "10.0"
  s.source       = { :git => "https://github.com/zumo/zumokit-react-native.git", :tag => "#{s.version}" }
  s.source_files  = "ios/**/*.{h,m,mm}"
  s.requires_arc = true


  s.dependency "React"
  s.dependency "ZumoKit", "#{s.version}"

end