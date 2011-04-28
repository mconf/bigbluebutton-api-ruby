$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = 'bigbluebutton-api-ruby'
  s.version = '0.0.10'
  s.extra_rdoc_files = ['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc']
  s.summary = 'Provides an interface to the BigBlueButton web meeting API (https://github.com/mconf/bigbluebutton-api-ruby)'
  s.description = s.summary
  s.authors = ['Leonardo Crauss Daronco', 'Joe Kinsella']
  s.email = ['leonardodaronco@gmail.com', 'joe.kinsella@gmail.com']
  s.homepage = "https://github.com/mconf/bigbluebutton-api-ruby/"
  s.bindir = "bin"
  s.files         = `git ls-files`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency('nokogiri', '~> 1.4.0')
end