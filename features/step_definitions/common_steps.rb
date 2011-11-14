# Common steps, used in several features

# Opens a yml file that defines the BBB test servers
# There can be several servers, the one used can be set using SERVER=name in the command line
def load_configs
  config_file = File.join(File.dirname(__FILE__), '..', 'config.yml')
  unless File.exist? config_file
    throw Exception.new(config_file + " does not exists. Copy the example and configure your server.")
  end
  @config = YAML.load_file(config_file)
  if ENV['SERVER']
    throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.") unless @config.has_key?(ENV['SERVER'])
    @config = @config[ENV['SERVER']]
  else
    @config = @config[@config.keys.first]
  end
  @config['bbb_version'] = '0.7' unless @config.has_key?('bbb_version')
end

When /^the default API object$/ do
  load_configs
  @api = BigBlueButton::BigBlueButtonApi.new(@config['bbb_url'], @config['bbb_salt'], @config['bbb_version'].to_s, false)
end

When /^that a meeting was created$/ do
  steps %Q{ When the default API object }

  @meeting_id = Forgery(:basic).random_name("test")
  @moderator_password = Forgery(:basic).password
  @response = @api.create_meeting(@meeting_id, @meeting_id, { :moderatorPW => @moderator_password })
end

When /^the meeting is running$/ do
  BigBlueButtonBot.new(@api, @meeting_id)
end

When /^the response is an error with the key "(.*)"$/ do |key|
  @exception.should_not be_nil
  @exception.key.should == key
end

When /^the response is successful$/ do
  @response[:returncode].should be_true
end

When /^the response has the messageKey "(.*)"$/ do |key|
  @response[:messageKey].should == key
end

When /^the response is successful and well formatted$/ do
  case @last_api_call
  when :create
    steps %Q{ When the response to the create method is successful and well formatted }
  when :end
    steps %Q{ When the response to the end method is successful and well formatted }
  end
end
