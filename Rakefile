require 'rubygems'
require 'rdoc/task'
require 'rubygems/package_task'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

desc 'Default: run tests.'
# task :default => [:spec, :cucumber]
task :default => :spec

RSpec::Core::RakeTask.new(:spec)

Cucumber::Rake::Task.new do |t|

  # Disable all features that need the bot. It isn't working since BigBlueButton 0.81.
  prepend = "--tags ~@need-bot"

  # in jruby the class BigBlueButtonBot doesn't work (it uses fork)
  if defined?(RUBY_ENGINE) and RUBY_ENGINE == 'jruby'
    puts "Jruby detected, ignoring features with @need-bot"
    prepend = "--tags ~@need-bot"
  end

  # defaults to the latest version, that runs all tests
  # if set to 0.8 only, won't run tests for newer versions
  if ENV["V"] == "0.8" or ENV["VERSION"] == "0.8"
    t.cucumber_opts = "--format pretty --tags ~@wip --tags @version-all #{prepend}"
  else
    t.cucumber_opts = "--format pretty --tags ~@wip --tags @version-all,@version-081 #{prepend}"
  end
end

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
