
Pod::Spec.new do |s|
  s.name         = "RNZumoKit"
  s.version      = "1.0.0"
  s.summary      = "RNZumoKit"
  s.description  = <<-DESC
                  RNZumoKit
                   DESC
  s.homepage     = "https://github.com/dlabs/zumokit-react-native"
  s.license      = "MIT"
  s.author       = { "author" => "Blockstar" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "ssh://github.com/dlabs/zumokit-react-native.git", :tag => "master" }
  s.source_files  = "ios/RNZumoKit/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end