# default call of create_meeting, should include all optional parameters
# to check if they are correctly stored
When /^the create method is called with all the optional arguments$/i do
  steps %Q{ When the default API object }

  @meeting_id = Forgery(:basic).random_name("test-create")
  @options = { :moderatorPW => Forgery(:basic).password,
               :attendeePW => Forgery(:basic).password,
               :welcome => Forgery(:lorem_ipsum).words(10),
               :dialNumber => Forgery(:basic).number(:at_most => 999999999).to_s,
               :logoutURL => Forgery(:internet).url,
               :voiceBridge => Forgery(:basic).number(:at_least => 70000, :at_most => 79999),
               :maxParticipants => Forgery(:basic).number }
  if @api.version >= "0.8"
    @options.merge!( { :record => true,
                       :duration => Forgery(:basic).number(:at_least => 10, :at_most => 60),
                       :meta_one => "one", :meta_TWO => "TWO" } )
  end
  @last_api_call = :create
  @response = @api.create_meeting(@meeting_id, @meeting_id, @options)
end

When /^the create method is called with no optional argument$/i do
  steps %Q{ When the default API object }

  @meeting_id = Forgery(:basic).random_name("test-create")
  @options = { }
  @last_api_call = :create
  @response = @api.create_meeting(@meeting_id, @meeting_id, @options)
end

When /^the create method is called with a duplicated meeting id$/ do
  steps %Q{ When the default API object }

  @meeting_id = Forgery(:basic).random_name("test-create")

  # first meeting
  @last_api_call = :create
  @api.create_meeting(@meeting_id, @meeting_id)

  begin
    # duplicated meeting to be tested
    @last_api_call = :create
    @response = @api.create_meeting(@meeting_id, @meeting_id)
  rescue Exception => @exception
  end
end

When /^the create method is called$/ do
  steps %Q{ When the default API object }

  @meeting_id = Forgery(:basic).random_name("test-create")
  @last_api_call = :create
  @response = @api.create_meeting(@meeting_id, @meeting_id)
end

When /^the meeting is forcibly ended$/ do
  @response = @api.end_meeting(@meeting_id, @response[:moderatorPW])
end

When /^the create method is called again with the same meeting id$/ do
  begin
    @last_api_call = :create
    @response = @api.create_meeting(@meeting_id, @meeting_id)
  rescue Exception => @exception
  end
end

When /^the response to the create method is successful and well formatted$/ do
  @response[:returncode].should be_true
  @response[:meetingID].should == @meeting_id
  @response[:hasBeenForciblyEnded].should be_false
  @response[:messageKey].should == ""
  @response[:message].should == ""

  if @options.has_key?(:attendeePW)
    @response[:attendeePW].should == @options[:attendeePW]
  else # auto generated password
    @response[:attendeePW].should be_a(String)
    @response[:attendeePW].should_not be_empty
    @options[:attendeePW] = @response[:attendeePW]
  end
  if @options.has_key?(:moderatorPW)
    @response[:moderatorPW].should == @options[:moderatorPW]
  else # auto generated password
    @response[:moderatorPW].should be_a(String)
    @response[:moderatorPW].should_not be_empty
    @options[:moderatorPW] = @response[:moderatorPW]
  end

  if @api.version >= "0.8"
    @response[:createTime].should be_a(Numeric)
  end
end

When /^the meeting exists in the server$/ do
  @response = @api.get_meetings
  @response[:meetings].reject!{ |m| m[:meetingID] != @meeting_id }
  @response[:meetings].count.should == 1
end

When /^it is configured with the parameters used in the creation$/ do
  @response = @api.get_meeting_info(@meeting_id, @options[:moderatorPW])
  @response[:meetingID].should == @meeting_id
  @response[:attendeePW].should == @options[:attendeePW]
  @response[:moderatorPW].should == @options[:moderatorPW]
  @response[:running].should be_false
  @response[:hasBeenForciblyEnded].should be_false
  @response[:startTime].should be_nil
  @response[:endTime].should be_nil
  @response[:participantCount].should == 0
  @response[:moderatorCount].should == 0
  @response[:attendees].should == []
  @response[:messageKey].should == ""
  @response[:message].should == ""

  if @api.version >= "0.8"
    @response[:meetingName].should == @meeting_id
    @response[:createTime].should be_a(Numeric)

    @options.has_key?(:record) ?
      (@response[:recording].should == @options[:record]) :
      (@response[:recording].should be_false)
    @options.has_key?(:maxParticipants) ?
      (@response[:maxUsers].should == @options[:maxParticipants]) :
      (@response[:maxUsers].should == 20)
    @options.has_key?(:voiceBridge) ?
      (@response[:voiceBridge].should == @options[:voiceBridge]) :
      (@response[:voiceBridge].should be_a(Numeric))

    if @options.has_key?(:maxParticipants)
      @response[:metadata].size.should == 2
      @response[:metadata].should be_a(Hash)
      @response[:metadata].should include(:one => "one")
      @response[:metadata].should include(:two => "TWO")
    else
      @response[:metadata].should == {}
    end

    # note: the duration passed in the api call is not returned (so it won't be checked)
  end
end
