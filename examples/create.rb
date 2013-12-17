$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  num = rand(1000)
  meeting_name = "Test Meeting #{num}"
  meeting_id = "test-meeting-#{num}"
  moderator_name = "House"
  attendee_name = "Cameron"
  puts "---------------------------------------------------"
  options = { :moderatorPW => "54321",
    :attendeePW => "12345",
    :welcome => 'Welcome to my meeting',
    :dialNumber => '1-800-000-0000x00000#',
    :logoutURL => 'https://github.com/mconf/bigbluebutton-api-ruby',
    :maxParticipants => 25 }
  response = @api.create_meeting(meeting_name, meeting_id, options)
  puts "The meeting has been created with the response:"
  puts response.inspect

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
