source 'https://github.com/CocoaPods/Specs.git'
workspace 'RudderBraze.xcworkspace'
use_frameworks!
inhibit_all_warnings!
platform :ios, '13.0'

def shared_pods
    pod 'Rudder'
end

target 'RudderBraze' do
    project 'RudderBraze.xcodeproj'
    shared_pods
    pod 'Appboy-iOS-SDK', '~> 4.7.0'
end

target 'SampleAppObjC' do
    project 'Examples/SampleAppObjC/SampleAppObjC.xcodeproj'
    shared_pods
    pod 'RudderBraze', :path => '.'
end

target 'SampleAppSwift' do
    project 'Examples/SampleAppSwift/SampleAppSwift.xcodeproj'
    shared_pods
    pod 'RudderBraze', :path => '.'
end
