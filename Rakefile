require 'rubygems'
require 'rdoc/task'
require 'rubygems/package_task'
require 'rspec/core/rake_task'

desc 'Default: run tests.'
task :default => :spec

RSpec::Core::RakeTask.new(:spec)

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include('README.md', 'LICENSE', 'LICENSE_003', 'CHANGELOG.md', 'lib/**/*.rb')
  rdoc.main = "README.md"
  rdoc.title = "bigbluebutton-api-ruby Docs"
  rdoc.rdoc_dir = 'rdoc'
end

eval("$specification = begin; #{IO.read('bigbluebutton-api-ruby.gemspec')}; end")
Gem::PackageTask.new $specification do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

task :notes do
  puts `grep -r 'OPTIMIZE\\|FIXME\\|TODO' lib/ spec/ features/`
end
