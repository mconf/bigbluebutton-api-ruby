$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib')

require 'bigbluebutton_api'
require 'forgery'
Dir["#{File.dirname(__FILE__)}/../../spec/support/forgery/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/../../extras/**/*.rb"].each { |f| require f }
