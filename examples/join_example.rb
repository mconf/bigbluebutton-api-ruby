$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  unless @api.is_meeting_running?(@config['meeting_id'])
    options = { :moderatorPW => @config['moderator_password'], :attendeePW => @config['attendee_password'], :welcome => 'Welcome to my meeting',
                :dialNumber => '1-800-000-0000x00000#', :logoutURL => 'https://github.com/mconf/bigbluebutton-api-ruby', :maxParticipants => 25 }
    @api.create_meeting(@config['meeting_name'], @config['meeting_id'], options)
    puts "The meeting has been created. Please open a web browser and enter the meeting as moderator."

    puts
    puts "---------------------------------------------------"
    url = @api.join_meeting_url(@config['meeting_id'], @config['moderator_name'], @config['moderator_password'])
    puts "1) Moderator URL = #{url}"

    puts
    puts "---------------------------------------------------"
    puts "Waiting 30 seconds for you to enter via browser"
    sleep(30)
  end

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
  puts
  puts
  puts "---------------------------------------------------"
  response = @api.join_meeting(@config['meeting_id'], @config['attendee_name'], @config['attendee_password'])
  puts "Join meeting response:"
  puts response.inspect

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
