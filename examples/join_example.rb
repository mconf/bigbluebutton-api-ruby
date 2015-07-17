$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  meeting_name = "Test Meeting"
  meeting_id = "test-meeting"
  moderator_name = "House"
  unless @api.is_meeting_running?(meeting_id)
    puts "---------------------------------------------------"
    options = { :moderatorPW => "54321",
      :attendeePW => "12345",
      :welcome => 'Welcome to my meeting',
      :dialNumber => '1-800-000-0000x00000#',
      :logoutURL => 'https://github.com/mconf/bigbluebutton-api-ruby',
      :maxParticipants => 25 }
    @api.create_meeting(meeting_name, meeting_id, options)
    puts "The meeting has been created. Please open a web browser and enter the meeting using either of the URLs below."

    puts
    puts "---------------------------------------------------"
    url = @api.join_meeting_url(meeting_id, moderator_name, options[:moderatorPW])
    puts "1) Moderator URL = #{url}"

    puts
    puts "---------------------------------------------------"
    puts "Waiting 30 seconds for you to enter via browser"
    sleep(30)
  end

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

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
