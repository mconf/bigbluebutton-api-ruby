$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = 'bigbluebutton-api-ruby'
  s.version = '0.0.4'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'LICENSE', 'CHANGELOG.rdoc']
  s.summary = 'Provides an interface to the BigBlueButton web meeting API (https://github.com/mconf/bigbluebutton-api-ruby)'
  s.description = s.summary
  s.authors = ['Leonardo Crauss Daronco', 'Joe Kinsella']
  s.email = ['leonardodaronco@gmail.com', 'joe.kinsella@gmail.com']
  s.homepage = "https://github.com/mconf/bigbluebutton-api-ruby/"
  s.bindir = "bin"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end