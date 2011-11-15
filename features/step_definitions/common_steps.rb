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
    unless @config['servers'].has_key?(ENV['SERVER'])
      throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.")
    end
    @config_server = @config['servers'][ENV['SERVER']]
  else
    @config_server = @config['servers'][@config['servers'].keys.first]
  end
  @config_server['bbb_version'] = '0.7' unless @config_server.has_key?('bbb_version')
end

When /^the default BigBlueButton server$/ do
  load_configs
  @api = BigBlueButton::BigBlueButtonApi.new(@config_server['bbb_url'],
                                             @config_server['bbb_salt'],
                                             @config_server['bbb_version'].to_s,
                                             @config['debug'])
end

# default create call, with no optional parameters (only the mod pass)
When /^that a meeting was created$/ do
  steps %Q{ When the default BigBlueButton server }

  @req = TestApiRequest.new
  @req.id = Forgery(:basic).random_name("test")
  @req.name = @req.id
  @req.mod_pass = Forgery(:basic).password
  @req.opts = { :moderatorPW => @req.mod_pass }
  @req.method = :create
  @req.response = @api.create_meeting(@req.id, @req.name, @req.opts)
end

When /^that a meeting was created with all the optional arguments$/i do
  steps %Q{ When the default BigBlueButton server }

  @req = TestApiRequest.new
  @req.id = Forgery(:basic).random_name("test-create")
  @req.name = @req.id
  @req.mod_pass = Forgery(:basic).password
  @req.opts = { :moderatorPW => @req.mod_pass,
                :attendeePW => Forgery(:basic).password,
                :welcome => Forgery(:lorem_ipsum).words(10),
                :dialNumber => Forgery(:basic).number(:at_most => 999999999).to_s,
                :logoutURL => Forgery(:internet).url,
                :voiceBridge => Forgery(:basic).number(:at_least => 70000, :at_most => 79999),
                :maxParticipants => Forgery(:basic).number }
  if @api.version >= "0.8"
    @req.opts.merge!( { :record => false,
                        :duration => Forgery(:basic).number(:at_least => 10, :at_most => 60),
                        :meta_one => "one", :meta_TWO => "TWO" } )
  end
  @req.method = :create
  @req.response = @api.create_meeting(@req.id, @req.name, @req.opts)
end

When /^the meeting is running$/ do
  BigBlueButtonBot.new(@api, @req.id)
end

When /^the response is an error with the key "(.*)"$/ do |key|
  @req.exception.should_not be_nil
  @req.exception.key.should == key
end

When /^the response is successful$/ do
  @req.response[:returncode].should be_true
end

When /^the response has the messageKey "(.*)"$/ do |key|
  @req.response[:messageKey].should == key
end

When /^the response is successful and well formatted$/ do
  case @req.method
  when :create
    steps %Q{ When the response to the create method is successful and well formatted }
  when :end
    steps %Q{ When the response to the end method is successful and well formatted }
  when :get_recordings
    steps %Q{ When the response to the get_recordings method is successful and well formatted }
  end
end

When /^the response to the create method is successful and well formatted$/ do
  @req.response[:returncode].should be_true
  @req.response[:meetingID].should == @req.id
  @req.response[:hasBeenForciblyEnded].should be_false
  @req.response[:messageKey].should == ""
  @req.response[:message].should == ""

  if @req.opts.has_key?(:attendeePW)
    @req.response[:attendeePW].should == @req.opts[:attendeePW]
  else # auto generated password
    @req.response[:attendeePW].should be_a(String)
    @req.response[:attendeePW].should_not be_empty
    @req.opts[:attendeePW] = @req.response[:attendeePW]
  end
  if @req.opts.has_key?(:moderatorPW)
    @req.response[:moderatorPW].should == @req.opts[:moderatorPW]
  else # auto generated password
    @req.response[:moderatorPW].should be_a(String)
    @req.response[:moderatorPW].should_not be_empty
    @req.opts[:moderatorPW] = @req.response[:moderatorPW]
  end

  if @api.version >= "0.8"
    @req.response[:createTime].should be_a(Numeric)
  end
end

When /^the response to the end method is successful and well formatted$/ do
  @req.response[:returncode].should be_true
  @req.response[:messageKey].should == "sentEndMeetingRequest"
  @req.response[:message].should_not be_empty
end

When /^the response to the get_recordings method is successful and well formatted$/ do
  @req.response[:returncode].should be_true
  @req.response[:recordings].should == []
end
