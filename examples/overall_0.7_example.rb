$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
#require 'thread'
require 'prepare'

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
  options = { :moderatorPW => @config['moderator_password'], :attendeePW => @config['attendee_password'], :welcome => 'Welcome to my meeting',
              :dialNumber => '1-800-000-0000x00000#', :logoutURL => 'https://github.com/mconf/bigbluebutton-api-ruby', :maxParticipants => 25 }
  @api.create_meeting(@config['meeting_name'], @config['meeting_id'], options)
  puts "The meeting has been created. Please open a web browser and enter the meeting using either of the URLs below."

  puts
  puts "---------------------------------------------------"
  url = @api.join_meeting_url(@config['meeting_id'], @config['moderator_name'], @config['moderator_password'])
  puts "1) Moderator URL = #{url}"
  puts ""
  url = @api.join_meeting_url(@config['meeting_id'], @config['attendee_name'], @config['attendee_password'])
  puts "2) Attendee URL = #{url}"

  puts
  puts "---------------------------------------------------"
  puts "Waiting 30 seconds for you to enter via browser"
  sleep(30)

  unless @api.is_meeting_running?(@config['meeting_id'])
    puts "You have NOT entered the meeting"
    Kernel.exit!
  end
  puts "You have successfully entered the meeting"

  puts
  puts "---------------------------------------------------"
  response = @api.get_meeting_info(@config['meeting_id'], @config['moderator_password'])
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
  @api.end_meeting(@config['meeting_id'], @config['moderator_password'])
  puts "The meeting has been ended"

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
