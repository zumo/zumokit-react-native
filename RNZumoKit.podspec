
Pod::Spec.new do |s|
  s.name         = "RNZumoKit"
  s.version      = "1.0.0"
  s.summary      = "RNZumoKit"
  s.description  = <<-DESC
                  RNZumoKit
                   DESC
  s.homepage     = "https://github.com/dlabs/zumokit-react-native"
  s.license      = "MIT"
  s.author       = { "author" => "Zumo" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "ssh://github.com/dlabs/zumokit-react-native.git", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m,mm}"
  s.requires_arc = true


  s.dependency "React"
  s.dependency "ZumoKit", "~> 1.2.0-beta.1"

end