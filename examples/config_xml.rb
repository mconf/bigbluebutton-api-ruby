$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.join(File.expand_path(File.dirname(__FILE__)), '..', 'lib')

require 'bigbluebutton_api'
require 'prepare'

begin
  prepare

  puts "---------------------------------------------------"
  config_xml = @api.get_default_config_xml
  config_xml = BigBlueButton::BigBlueButtonConfigXml.new(config_xml)
  puts "The default config.xml was taken from the server"

  puts "---------------------------------------------------"
  layouts = @api.get_available_layouts
  puts "The available layouts are"
  puts layouts.inspect
  puts "The default layouts are"
  puts @api.get_default_layouts.inspect

  puts "---------------------------------------------------"
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
  puts "A meeting has been created: #{meeting_id}"

  puts "---------------------------------------------------"
  url = @api.join_meeting_url(meeting_id, username, options[:moderatorPW])
  puts "Please join the meeting as moderator using the link: #{url}"
  puts "*** You will be using the DEFAULT config.xml ***"
  puts "Waiting 30 seconds for you to join..."
  puts
  sleep(30)

  puts "---------------------------------------------------"
  puts "Creating a new config.xml"
  # config_xml.set_attribute("layout", "showToolbar", "false", false)
  config_xml.set_attribute("skinning", "enabled", "false", false)
  config_xml.set_attribute("layout", "defaultLayout", "Webinar", false)
  config_xml.set_attribute("layout", "showLayoutTools", "false", false)
  config_xml.set_attribute("ChatModule", "privateEnabled", "false")
  config_xml.set_attribute("VideoconfModule", "resolutions", "320x240")
  config_xml.set_attribute("VideoconfModule", "presenterShareOnly", "true")

  puts "---------------------------------------------------"
  token = @api.set_config_xml(meeting_id, config_xml)
  puts "Setting the new config.xml returned the token: #{token}"

  puts "---------------------------------------------------"
  url = @api.join_meeting_url(meeting_id, username2, options[:moderatorPW], { :configToken => token })
  puts "Please join the meeting again using the link: #{url}"
  puts "*** You will be using the MODIFIED config.xml, with the following modifications: ***"
  puts "***  - Disabled layout (will show the default layout, as was used in BBB < 0.8)"
  puts "***  - Default layout to Webinar"
  puts "***  - Hidden layout tools"
  puts "***  - Disabled private chat"
  puts "***  - Restricted video resolutions to 320x240 only"
  puts "***  - Disabled video sharing except for the presenter"
  puts

rescue Exception => ex
  puts "Failed with error #{ex.message}"
  puts ex.backtrace
end
