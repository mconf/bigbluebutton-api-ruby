require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'

desc 'Default: run tests.'
task :default => :test

Rake::RDocTask.new do |rdoc|
  files =['README.rdoc', 'LICENSE', 'CHANGELOG.rdoc', 'lib/**/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "bigbluebutton-api-ruby Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

desc 'Test the gem.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/*test.rb'
  t.verbose = true
  t.libs << 'test'
end
