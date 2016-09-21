use_frameworks!

def testing_pods
    pod 'Quick', :branch => 'swift-3.0', :git => 'https://github.com/Quick/Quick.git'
    pod 'Nimble', '~> 5.0'
    pod 'SwiftyJSON', :branch => 'master', :git => 'https://github.com/IBM-Swift/SwiftyJSON.git'
end

target 'Kakapo iOSTests' do
	platform :ios, '9.0'
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
            configuration.build_settings['SWIFT_VERSION'] = "3.0"
        end
    end
end
