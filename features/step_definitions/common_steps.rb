# Common steps, used in several features

When /^the default BigBlueButton server$/ do
  @api = BigBlueButton::BigBlueButtonApi.new(@config_server['url'],
                                             @config_server['secret'],
                                             @config_server['version'].to_s,
                                             @config['debug'])
  @api.timeout = @config['timeout_req']
end

# default create call, with no optional parameters (only the mod pass)
When /^that a meeting was created$/ do
  steps %Q{ When the default BigBlueButton server }

  @req.id = Forgery(:basic).random_name("test")
  @req.name = @req.id
  @req.mod_pass = Forgery(:basic).password
  @req.opts = { :moderatorPW => @req.mod_pass }
  @req.method = :create
  @req.response = @api.create_meeting(@req.id, @req.name, @req.opts)
end

When /^that a meeting was created with all the optional arguments$/i do
  steps %Q{ When the default BigBlueButton server }

  @req.id = Forgery(:basic).random_name("test-create")
  @req.name = @req.id
  @req.mod_pass = Forgery(:basic).password
  @req.opts = { :moderatorPW => @req.mod_pass,
                :attendeePW => Forgery(:basic).password,
                :welcome => Forgery(:lorem_ipsum).words(10),
                :dialNumber => Forgery(:basic).number(:at_most => 999999999).to_s,
                :logoutURL => Forgery(:internet).url,
                :voiceBridge => Forgery(:basic).number(:at_least => 70000, :at_most => 79999),
                :webVoice => Forgery(:basic).text,
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
  steps %Q{ When the meeting is running with 1 attendees }
end

When /^the meeting is running with (\d+) attendees$/ do |count|
  BigBlueButtonBot.new(@api, @req.id, nil, count.to_i, @config['timeout_bot_start'])
end

When /^the response is an error with the key "(.*)"$/ do |key|
  @req.exception.should_not be_nil
  @req.exception.key.should == key
end

When /^the response is successful$/ do
  @req.response[:returncode].should be_true
end

When /^the response is successful with no messages$/ do
  @req.response[:returncode].should be_true
  @req.response[:messageKey].should == ""
  @req.response[:message].should == ""
end

When /^the response has the messageKey "(.*)"$/ do |key|
  @req.response[:messageKey].should == key
  @req.response[:message].should_not be_empty
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

  @req.opts = {} if @req.opts.nil?
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
