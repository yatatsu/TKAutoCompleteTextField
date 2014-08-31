# coding: utf-8
Pod::Spec.new do |s|
  s.name         = "TKAutoCompleteTextField"
  s.version      = "0.0.1"
  s.summary      = "Simple auto completion with UITextField"

  s.homepage     = "http://github.com/yatatsu/TKAutoCompleteTextField"
  s.screenshots  = "https://raw.githubusercontent.com/yatatsu/TKAutoCompleteTextField/master/TKAutoCompleteTextFieldSample.png"

  s.license      = { :type => "MIT", :file => "LICENSE" }
  
  s.author             = { "yatatsu" => "yatatsukitagawa@gmail.com" }

  s.platform     = :ios
  s.ios.deployment_target = "6.0"

  s.source       = { :git => "http://github.com/yatatsu/TKAutoCompleteTextField.git", :tag => "0.0.1" }

  s.source_files  = "TKAutoCompleteTextField/*.{h,m}"
  s.exclude_files = "TKAutoCompleteTextFieldSample", "TKAutoCompleteTextFieldTests"
  s.requires_arc  = true  
end
