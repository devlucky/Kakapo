Pod::Spec.new do |s|
  s.name             = "Kakapo"
  s.version          = "2.0.0"
  s.summary          = "Dynamically Mock server behaviors and responses."

  s.description      = <<-DESC
							Dynamically Mock server behaviors and responses.
  							Kakapo allows you to replicate your backend APIs and logic.
  							With Kakapo you can easily prototype your application based on your API specifications.
  							While usually network mocks involve using static json files Kakapo let you create Swift structs/classes/enums that are automatically serialized to JSON.
                       DESC

  s.homepage         = "https://github.com/devlucky/Kakapo"
  s.license          = 'MIT'
  s.author           = { "Alex Manzella" => "manzopower@icloud.com", "Joan Romano" => "joanromano@gmail.com" }
  s.source           = { :git => "https://github.com/devlucky/Kakapo.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/devluckyness'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.11'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.source_files = 'Source/**/*'

end
