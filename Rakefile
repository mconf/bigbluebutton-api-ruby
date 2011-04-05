require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/gempackagetask'

desc 'Default: run tests.'
task :default => :test

Rake::RDocTask.new do |rdoc|
  files = ['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "bigbluebutton-api-ruby Docs"
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

eval("$specification = begin; #{ IO.read('bigbluebutton-api-ruby.gemspec')}; end")
Rake::GemPackageTask.new $specification do |pkg|
  pkg.need_tar = true
  pkg.need_zip = true
end

desc 'Test the gem.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*test.rb'
  t.verbose = true
  t.libs << 'test'
end
