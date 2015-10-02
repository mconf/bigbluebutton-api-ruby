$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  puts
  puts "---------------------------------------------------"
  puts "The version of your BBB server is: #{@api.get_api_version}"
rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
