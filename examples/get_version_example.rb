$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  @api = BigBlueButton::BigBlueButtonApi.new(@config['bbb_url'], @config['bbb_salt'], nil, true)

  puts
  puts "---------------------------------------------------"
  puts "The version of your BBB server is: #{@api.version}"
rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
