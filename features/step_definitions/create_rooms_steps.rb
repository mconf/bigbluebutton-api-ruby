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

When /^the method to create a meeting is called with meeting ID "(.*)"$/ do |id|
  @meeting_id = Forgery(:basic).random_name(id)
  @options = { :moderatorPW => Forgery(:basic).password,
               :attendeePW => Forgery(:basic).password,
               :welcome => Forgery(:lorem_ipsum).words(10),
               :dialNumber => Forgery(:basic).number(:at_most => 999999999).to_s,
               :logoutURL => Forgery(:internet).url,
               :maxParticipants => Forgery(:basic).number }
  @response = @api.create_meeting(@meeting_id, @meeting_id, @options)
end

Then /^the response is successful and well formatted$/ do
  @response[:returncode].should be_true
  @response[:meetingID].should == @meeting_id
  @response[:attendeePW].should == @options[:attendeePW]
  @response[:moderatorPW].should == @options[:moderatorPW]
  @response[:hasBeenForciblyEnded].should be_false
  @response[:messageKey].should == ""
  @response[:message].should == ""
  if @api.version >= "0.8"
  # @response[:createTime].should
  end
end

Then /^the meeting exists in the server$/ do
  @response = @api.get_meetings
  @response[:meetings].reject!{ |m| m[:meetingID] != @meeting_id }
  @response[:meetings].count.should == 1
end

Then /^it is configured with the parameters used in the creation$/ do
  @response = @api.get_meeting_info(@meeting_id, @options[:moderatorPW])
  @response[:meetingID].should == @meeting_id
  # @response[:voiceBridge].should
  @response[:attendeePW].should == @options[:attendeePW]
  @response[:moderatorPW].should == @options[:moderatorPW]
  @response[:running].should be_false
  @response[:hasBeenForciblyEnded].should be_false
  # @response[:startTime].should
  # @response[:endTime].should
  @response[:participantCount].should == 0
  @response[:moderatorCount].should == 0
  @response[:attendees].should == []
  @response[:messageKey].should == ""
  @response[:message].should == ""

  if @api.version >= "0.8"
    @response[:meetingName].should == @meeting_id
    @response[:recording].should be_false
    @response[:maxUsers].should == @options[:maxParticipants]
  # @response[:createTime].should == @options[:attendeePW] # TODO:
    @response[:metadata].should == {}
  end
end
