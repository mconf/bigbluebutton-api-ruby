$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name             = "bigbluebutton-api-ruby"
  s.version          = "2.0.0-rc.1"
  s.licenses         = ["MIT"]
  s.extra_rdoc_files = ["README.md", "LICENSE", "LICENSE_003", "CHANGELOG.md"]
  s.summary          = "BigBlueButton integration for ruby"
  s.description      = "Provides methods to access BigBlueButton in a ruby application through its API"
  s.authors          = ["Mconf", "Leonardo Crauss Daronco"]
  s.email            = ["contact@mconf.org", "leonardodaronco@gmail.com"]
  s.homepage         = "https://github.com/mconf/bigbluebutton-api-ruby/"
  s.bindir           = "bin"
  s.files            = `git ls-files`.split("\n")
  s.require_paths    = ["lib"]
  s.required_ruby_version = '>= 3.2.0'

  s.add_runtime_dependency('xml-simple', '~> 1.1')
  s.add_runtime_dependency('base64', '>= 0.1.0')
end
