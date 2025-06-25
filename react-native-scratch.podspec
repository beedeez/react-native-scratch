require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name             = package['name']
  s.version          = package['version']
  s.summary          = package['description']
  s.description      = package['description']
  s.license          = package['license']
  s.author           = package['author']
  s.homepage         = 'https://github.com/beedeez/react-native-scratch'
  s.source           = { :git => 'https://github.com/beedeez/react-native-scratch' }

  s.requires_arc     = true
  s.platform         = :ios, '12.4'
  s.swift_version    = '5.0'

  s.preserve_paths   = 'README.md', 'package.json', 'index.js'
  s.source_files     = 'ios/*.{h,m}'
  s.header_dir       = 'RNTScratchView'

  # React Native dependencies for new architecture compatibility
  if ENV['RCT_NEW_ARCH_ENABLED'] == '1'
    s.compiler_flags = folly_compiler_flags + ' -DRCT_NEW_ARCH_ENABLED=1'
    s.pod_target_xcconfig = {
      'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/boost"',
      'OTHER_CPLUSPLUSFLAGS' => '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1',
      'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17'
    }
    s.dependency 'React-Codegen'
    s.dependency 'RCT-Folly'
    s.dependency 'RCTRequired'
    s.dependency 'RCTTypeSafety'
    s.dependency 'ReactCommon/turbomodule/core'
  end

  s.dependency 'React-Core'

  # Define folly_compiler_flags if not already defined
  def folly_compiler_flags
    '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'
  end

end
