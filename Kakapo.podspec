Pod::Spec.new do |s|
  s.name             = "Kakapo"
  s.version          = "0.0.1-alpha3"
  s.summary          = "Next generation network mocking library."

  s.description      = <<-DESC 
  							Next generation network mocking library. WIP
                       DESC

  s.homepage         = "https://github.com/devlucky/Kakapo"
  s.license          = 'MIT'
  s.author           = { "Alex Manzella" => "manzopower@icloud.com", "Joan Romano" => "joanromano@gmail.com" }
  s.source           = { :git => "https://github.com/devlucky/Kakapo.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/devluckyness'

  s.ios.deployment_target = '8.0'

  s.source_files = 'Source/**/*'
  
end
