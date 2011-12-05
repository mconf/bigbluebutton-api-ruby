$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', 'lib')

require 'bigbluebutton_api'
require 'bigbluebutton_bot'
require 'forgery'
Dir["#{File.dirname(__FILE__)}/../../spec/support/forgery/**/*.rb"].each { |f| require f }
