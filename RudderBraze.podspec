Pod::Spec.new do |s|
    s.name             = 'RudderBraze'
    s.version          = '1.2.0'
    s.summary          = 'Privacy and Security focused Segment-alternative. Braze Native SDK integration support.'

    s.description      = <<-DESC
Rudder is a platform for collecting, storing and routing customer event data to dozens of tools. Rudder is open-source, can run in your cloud environment (AWS, GCP, Azure or even your data-centre) and provides a powerful transformation framework to process your event data on the fly.
                       DESC

    s.homepage         = 'https://github.com/rudderlabs/rudder-integration-braze-swift'
    s.license          = { :type => "Elastic License 2.0", :file => "LICENSE.md" }
    s.author           = { 'RudderStack' => 'arnab@rudderlabs.com' }
    s.source           = { :git => 'https://github.com/rudderlabs/rudder-integration-braze-swift.git', :tag => "v#{s.version}" }

    s.ios.deployment_target = '13.0'
    
    s.source_files = 'Sources/**/*{h,m,swift}'
    s.module_name = 'RudderBraze'
    s.swift_version = '5.3'

    s.dependency 'Rudder', '~> 2.2.4'
    s.dependency 'Appboy-iOS-SDK', '~> 4.7.0'
end
