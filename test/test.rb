require 'bigbluebutton'
require 'thread'

begin
  BBB_SECURITY_SALT = '639259d4-9dd8-4b25-bf01-95f9567eaf4b'
  BBB_URL = 'http://devbuild.bigbluebutton.org/bigbluebutton/api'

  BBB_VERSION = '0.7'
  MEETING_ID = 'bigbluebutton-api-ruby-test4'
  MEETING_NAME = 'Test Meeting For Ruby Gem'
  MODERATOR_PASSWORD = '4321'
  MODERATOR_NAME = 'Jake'
  ATTENDEE_PASSWORD = '1234'
  ATTENDEE_NAME = 'Eben'

  api = BigBlueButton::BigBlueButtonApi.new(BBB_URL, BBB_SECURITY_SALT, BBB_VERSION, true)

  puts
  puts "---------------------------------------------------"
  response = api.get_meetings
  puts "Existent meetings in your server"
  response[:meetings][:meeting].each do |m|
    puts 'ID: ' + m[:meetingID]
    puts '    Info: ' + m.inspect
  end

  puts
  puts "---------------------------------------------------"
  api.create_meeting(MEETING_NAME, MEETING_ID, MODERATOR_PASSWORD, ATTENDEE_PASSWORD, 'Welcome to my meeting', '1-800-000-0000x00000#', 'https://github.com/mconf/bigbluebutton-api-ruby', 10)
  puts "The meeting has been created.  Please open a web browser and enter the meeting using either of the below URLs."

  puts
  puts "---------------------------------------------------"
  url = api.moderator_url(MEETING_ID, MODERATOR_NAME, MODERATOR_PASSWORD)
  puts "1) Moderator URL = #{url}"
  puts ""
  url = api.attendee_url(MEETING_ID, ATTENDEE_NAME, ATTENDEE_PASSWORD)
  puts "2) Attendee URL = #{url}"

  puts
  puts "---------------------------------------------------"
  puts "Waiting 30 seconds for you to enter via browser"
  sleep(30)

  unless api.is_meeting_running?(MEETING_ID)
    puts "You have NOT entered the meeting"
    Kernel.exit!
  end
  puts "You have successfully entered the meeting"

  puts
  puts "---------------------------------------------------"
  response = api.get_meeting_info(MEETING_ID, MODERATOR_PASSWORD)
  puts "Meeting info:"
  puts response.inspect

  puts
  puts "---------------------------------------------------"
  api.end_meeting(MEETING_ID, MODERATOR_PASSWORD)
  puts "The meeting has been ended"

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
