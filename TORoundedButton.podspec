Pod::Spec.new do |s|
  s.name     = 'TORoundedButton'
  s.version  = '1.1.0'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A high-performance button control with rounded corners for iOS.'
  s.homepage = 'https://github.com/TimOliver/TORoundedButton'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TORoundedButton.git', :tag => s.version }
  s.platform = :ios, '10.0'
  s.source_files = 'TORoundedButton/**/*.{h,m}'
  s.requires_arc = true
end
