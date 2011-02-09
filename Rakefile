# 
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'

spec = Gem::Specification.new do |s|
  s.name = 'bigbluebutton-api-ruby'
  s.version = '0.0.4'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'LICENSE']
  s.summary = 'Provides an interface to the BigBlueButton web meeting API (https://github.com/mconf/bigbluebutton-api-ruby)'
  s.description = s.summary
  s.author = 'Leonardo Crauss Daronco'
  s.email = 'leonardodaronco@gmail.com'
  s.homepage = "https://github.com/mconf/bigbluebutton-api-ruby/"
  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{bin,lib,doc,test,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
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
