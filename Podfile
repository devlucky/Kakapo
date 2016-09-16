use_frameworks!

def testing_pods
    pod 'Quick', '~> 0.9'
    pod 'Nimble', '~> 4.0'
    pod 'SwiftyJSON', :git => 'https://github.com/TheSufferfest/SwiftyJSON.git', :branch => 'master'
    pod 'Alamofire', '~> 3.5.0'
    pod 'AFNetworking'
end

target 'Kakapo iOSTests' do
	platform :ios, '8.0'
    testing_pods
end

target 'Kakapo tvOSTests' do
	platform :tvos, '9.2'
    testing_pods
end

target 'Kakapo macOSTests' do
	platform :osx, '10.11'
    testing_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |configuration|
            configuration.build_settings['SWIFT_VERSION'] = "2.3"
        end
    end
end
