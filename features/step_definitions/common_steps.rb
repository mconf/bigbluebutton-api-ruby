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

# default create call, with no optional parameters (only the mod pass)
When /^that a meeting was created$/ do
  steps %Q{ When the default API object }

  @req = TestApiRequest.new
  @req.id = Forgery(:basic).random_name("test")
  @req.name = @req.id
  @req.opts = { :moderatorPW => Forgery(:basic).password }
  @req.method = :create
  @req.response = @api.create_meeting(@req.id, @req.name, @req.opts)
end

When /^that a meeting was created with all the optional arguments$/i do
  steps %Q{ When the default API object }

  @req = TestApiRequest.new
  @req.id = Forgery(:basic).random_name("test-create")
  @req.name = @req.id
  @req.opts = { :moderatorPW => Forgery(:basic).password,
                :attendeePW => Forgery(:basic).password,
                :welcome => Forgery(:lorem_ipsum).words(10),
                :dialNumber => Forgery(:basic).number(:at_most => 999999999).to_s,
                :logoutURL => Forgery(:internet).url,
                :voiceBridge => Forgery(:basic).number(:at_least => 70000, :at_most => 79999),
                :maxParticipants => Forgery(:basic).number }
  if @api.version >= "0.8"
    @req.opts.merge!( { :record => true,
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
  end
end
