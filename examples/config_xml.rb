$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  configXml = @api.get_default_config_xml
  puts "---------------------------------------------------"
  puts "The default config.xml was taken from the server"

  num = rand(1000)
  meeting_name = "Test Meeting #{num}"
  meeting_id = "test-meeting-#{num}"
  username = "House #{rand(1000)}"
  username2 = "Cameron #{rand(1000)}"
  options = { :moderatorPW => "54321",
    :attendeePW => "12345",
    :welcome => 'Welcome to my meeting',
    :dialNumber => '1-800-000-0000x00000#',
    :logoutURL => 'https://github.com/mconf/bigbluebutton-api-ruby',
    :maxParticipants => 25 }
  response = @api.create_meeting(meeting_name, meeting_id, options)
  puts "---------------------------------------------------"
  puts "A meeting has been created: #{meeting_id}"

  puts "---------------------------------------------------"
  url = @api.join_meeting_url(meeting_id, username, options[:moderatorPW])
  puts "Please join the meeting as moderator using the link: #{url}"
  puts "*** You will be using the DEFAULT config.xml ***"
  puts "Waiting 30 seconds for you to join..."
  puts
  sleep(30)

  puts "---------------------------------------------------"
  puts "Creating a new config.xml without the toolbar"
  newConfig = configXml.gsub(/showToolbar=[^ ]*/, 'showToolbar="false"')

  token = @api.set_config_xml(meeting_id, newConfig)
  puts "---------------------------------------------------"
  puts "Setting the new config.xml returned the token: #{token}"

  puts "---------------------------------------------------"
  url = @api.join_meeting_url(meeting_id, username2, options[:moderatorPW], { :configToken => token })
  puts "Please join the meeting again using the link: #{url}"
  puts "*** You will be using the MODIFIED config.xml ***"
  puts

  # create a meeting

  # give a link to join with the default config.xml

  # set a custom config.xml

  # give a link to join with the custom config.xml

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
