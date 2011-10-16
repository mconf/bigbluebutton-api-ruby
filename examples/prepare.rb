$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
#require 'thread'
require 'yaml'

def prepare
  config_file = File.join(File.dirname(__FILE__), 'config.yml')
  unless File.exist? config_file
    puts config_file + " does not exists. Copy the example and configure your server."
    puts "cp test/config.yml.example test/config.yml"
    puts
    Kernel.exit!
  end
  @config = YAML.load_file(config_file)

  puts "config:"
  @config.each do |k,v|
    puts k + ": " + v
  end

  @api = BigBlueButton::BigBlueButtonApi.new(@config['bbb_url'], @config['bbb_salt'], @config['bbb_version'].to_s, true)
end
