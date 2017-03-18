#
# Be sure to run `pod lib lint Mist.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|

  s.name             = 'Mist'
  s.version          = '0.1.0'
  s.summary          = 'An adapter for CloudKit that supports local persistence, custom typed models, true relationships, & automatic sync.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Mist was created because **CloudKit is great, but it has some fundamental shortcomings**:

* Although it lets you sync records between cloud and device, it doesn't let you save them locally once they've arrived;
* Although it has a flexible approach to data modelling, that flexibility makes it verbose and error-prone to use;
* Although it has incredible features for synchronization, they're arcane & opt-in rather than obvious & automatic.

Mist seeks to solve these problems by directly supporting **local persistence**, by requiring the use of **typed models with true relationships**, & by providing **automatic synchronization**. 
                       DESC

  s.homepage         = 'https://github.com/mmccroskey/Mist'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Matthew McCroskey' => 'mist@crazytaps.biz' }
  s.source           = { :git => 'https://github.com/Matthew McCroskey/Mist.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/mmccroskey'

  s.ios.deployment_target = '10.0'

  s.source_files = 'Mist/Classes/**/*'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CloudKit'
  # s.dependency 'AFNetworking', '~> 2.3'

end
