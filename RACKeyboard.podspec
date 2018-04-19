Pod::Spec.new do |s|
  s.name             = 'RACKeyboard'
  s.version          = '0.1.0'
  s.summary          = 'Reactive Keyboard in iOS , reference from  RxKeyboard'
  s.homepage         = 'https://github.com/arcangelw/RACKeyboard'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'arcangelw' => 'wuzhezmc@gmail.com' }
  s.source           = { :git => 'https://github.com/arcangelw/RACKeyboard.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'RACKeyboard/Classes/**/*.swift'
  s.frameworks = 'UIKit'
  s.dependency 'ReactiveCocoa', '~> 7.0.0'
end
