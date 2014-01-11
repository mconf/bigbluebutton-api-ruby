$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'
require 'securerandom'

begin
  prepare

  puts
  puts "---------------------------------------------------"
  if @api.test_connection
    puts "Connection successful! continuing..."
  else
    puts "Connection failed! The server might be unreachable. Exiting..."
    Kernel.exit!
  end

  puts
  puts "---------------------------------------------------"
  version = @api.get_api_version
  puts "The API version of your server is #{version}"

  puts
  puts "---------------------------------------------------"
  response = @api.get_meetings
  puts "Existent meetings in your server:"
  response[:meetings].each do |m|
    puts "  " + m[:meetingID] + ": " + m.inspect
  end

  puts
  puts "---------------------------------------------------"
  response = @api.get_recordings
  puts "Existent recordings in your server:"
  response[:recordings].each do |m|
    puts "  " + m[:recordID] + ": " + m.inspect
  end

  puts
  puts "---------------------------------------------------"
  meeting_id = SecureRandom.hex(4)
  meeting_name = meeting_id
  moderator_name = "House"
  attendee_name = "Cameron"
  options = { :moderatorPW => "54321",
              :attendeePW => "12345",
              :welcome => 'Welcome to my meeting',
              :dialNumber => '1-800-000-0000x00000#',
              :voiceBridge => 70000 + rand(9999),
              :webVoice => SecureRandom.hex(4),
              :logoutURL => 'https://github.com/mconf/bigbluebutton-api-ruby',
              :maxParticipants => 25 }

  @api.create_meeting(meeting_name, meeting_id, options)
  puts "The meeting has been created. Please open a web browser and enter the meeting using either of the URLs below."

  puts
  puts "---------------------------------------------------"
  url = @api.join_meeting_url(meeting_id, moderator_name, options[:moderatorPW])
  puts "1) Moderator URL = #{url}"
  puts ""
  url = @api.join_meeting_url(meeting_id, attendee_name, options[:attendeePW])
  puts "2) Attendee URL = #{url}"

  puts
  puts "---------------------------------------------------"
  puts "Waiting 30 seconds for you to enter via browser"
  sleep(30)

  unless @api.is_meeting_running?(meeting_id)
    puts "You have NOT entered the meeting"
    Kernel.exit!
  end
  puts "You have successfully entered the meeting"

  puts
  puts "---------------------------------------------------"
  response = @api.get_meeting_info(meeting_id, options[:moderatorPW])
  puts "Meeting info:"
  puts response.inspect

  puts
  puts "---------------------------------------------------"
  puts "Attendees:"
  response[:attendees].each do |m|
    puts "  " + m[:fullName] + " (" +  m[:userID] + "): " + m.inspect
  end


  puts
  puts "---------------------------------------------------"
  @api.end_meeting(meeting_id, options[:moderatorPW])
  puts "The meeting has been ended"

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
