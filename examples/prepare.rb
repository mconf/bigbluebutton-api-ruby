$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'yaml'

def prepare
  config_file = File.join(File.dirname(__FILE__), '..', 'features', 'config.yml')
  unless File.exist? config_file
    puts config_file + " does not exists. Copy the example and configure your server."
    puts "cp features/config.yml.example features/config.yml"
    puts
    Kernel.exit!
  end
  @config = YAML.load_file(config_file)

  puts "** Config:"
  @config.each do |k,v|
    puts k + ": " + v.to_s
  end
  puts

  if ARGV.size > 0
    unless @config['servers'].has_key?(ARGV[0])
      throw Exception.new("Server #{ARGV[0]} does not exists in your configuration file.")
    end
    server = @config['servers'][ARGV[0]]
  else
    key = @config['servers'].keys.first
    server = @config['servers'][key]
  end

  puts "** Using the server:"
  puts server.inspect
  puts

  @api = BigBlueButton::BigBlueButtonApi.new(server['url'], server['secret'], server['version'].to_s, true)
end
