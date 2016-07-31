Pod::Spec.new do |s|
  s.name             = "Kakapo"
  s.version          = "0.0.1-beta2"
  s.summary          = "Dynamically Mock server behaviors and APIs, prototype without backend."

  s.description      = <<-DESC 
  							Dynamically Mock server behaviors and APIs, prototype without backend.
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
