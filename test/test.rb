require 'bigbluebutton'
require 'thread'

begin
  BBB_SECURITY_SALT = '639259d4-9dd8-4b25-bf01-95f9567eaf4b'
  BBB_URL = 'http://devbuild.bigbluebutton.org/bigbluebutton/api'
  MEETING_ID = 'ruby_gem_test'
  MEETING_NAME = 'Test Meeting For Ruby Gem'
  MODERATOR_PASSWORD = '4321'
  MODERATOR_NAME = 'Jake'
  ATTENDEE_PASSWORD = '1234'
  ATTENDEE_NAME = 'Eben'

  api = BigBlueButton::BigBlueButtonApi.new(BBB_URL, BBB_SECURITY_SALT)
  api.create_meeting(MEETING_ID, MEETING_NAME, MODERATOR_PASSWORD, ATTENDEE_PASSWORD, 'Welcome to my meeting', '1-800-000-0000x00000#', 'http://code.google.com/p/bigbluebuttongem/', 10)
  puts ""
  puts "The meeting has been created.  Please open a web browser and enter the meeting using either of the below URLs."

  url = api.moderator_url(MEETING_ID, MODERATOR_NAME, MODERATOR_PASSWORD)
  url = api.attendee_url(MEETING_ID, ATTENDEE_NAME, ATTENDEE_PASSWORD)
  puts "1) Moderator URL = #{url}"
  puts ""
  puts "2) Attendee URL = #{url}"

  puts ""
  puts "Waiting 60 seconds for you to enter via browser"
  sleep(60)

  unless api.is_meeting_running(MEETING_ID)
    puts "You have NOT entered the meeting"
    Kernel.exit!
  end
  puts "You have successfully entered the meeting"

  xml_doc = api.get_meeting_info(MEETING_ID, MODERATOR_PASSWORD)
  puts "The meeting token for this meeting is: #{xml_doc.root.get_text('/response/meetingToken').to_s}"
  api.end_meeting(MEETING_ID, MODERATOR_PASSWORD)
  puts "The meeting has been ended"
rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end