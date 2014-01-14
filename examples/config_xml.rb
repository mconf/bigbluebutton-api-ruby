$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  configXml = @api.get_default_config_xml
  puts "---------------------------------------------------"
  puts "The default config.xml was taken from the server"

  # create a meeting

  # give a link to join with the default config.xml

  # set a custom config.xml

  # give a link to join with the custom config.xml

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
