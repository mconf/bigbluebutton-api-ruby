When /^the method isMeetingRunning informs that the meeting is running$/ do
  @req.response = @api.is_meeting_running?(@req.id)
  @req.response.should be_true
end

When /^the method isMeetingRunning informs that the meeting is not running$/i do
  @req.response = @api.is_meeting_running?(@req.id)
  @req.response.should be_false
end

When /^calling the method get_meetings$/ do
  @req.response = @api.get_meetings
end

When /^calling the method get_meeting_info$/ do
  @req.response = @api.get_meeting_info(@req.id, @req.mod_pass)
end

When /^the created meeting should be listed in the response with proper information$/ do
  @req.response[:meetings].size.should >= 1

  # the created meeting is in the list and has only 1 occurance
  found = @req.response[:meetings].reject{ |m| m[:meetingID] != @req.id }
  found.should_not be_nil
  found.size.should == 1

  # proper information in the meeting hash
  found = found[0]
  found[:attendeePW].should be_a(String)
  found[:attendeePW].should_not be_empty
  found[:moderatorPW].should == @req.mod_pass
  found[:hasBeenForciblyEnded].should be_false
  found[:running].should be_false
  if @api.version >= "0.8"
    found[:meetingName].should == @req.id
    found[:createTime].should be_a(Numeric)
  end
end

When /^it shows all the information of the meeting that was created$/ do
  @req.response = @api.get_meeting_info(@req.id, @req.mod_pass)
  @req.response[:meetingID].should == @req.id
  @req.response[:running].should be_false
  @req.response[:hasBeenForciblyEnded].should be_false
  @req.response[:startTime].should be_nil
  @req.response[:endTime].should be_nil
  @req.response[:participantCount].should == 0
  @req.response[:moderatorCount].should == 0
  @req.response[:attendees].should == []
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
    @req.response[:meetingName].should == @req.id
    @req.response[:createTime].should be_a(Numeric)

    @req.opts.has_key?(:record) ?
      (@req.response[:recording].should == @req.opts[:record]) :
      (@req.response[:recording].should be_false)
    @req.opts.has_key?(:maxParticipants) ?
      (@req.response[:maxUsers].should == @req.opts[:maxParticipants]) :
      (@req.response[:maxUsers].should == 20)
    @req.opts.has_key?(:voiceBridge) ?
      (@req.response[:voiceBridge].should == @req.opts[:voiceBridge]) :
      (@req.response[:voiceBridge].should be_a(Numeric))

    if @req.opts.has_key?(:maxParticipants)
      @req.response[:metadata].size.should == 2
      @req.response[:metadata].should be_a(Hash)
      @req.response[:metadata].should include(:one => "one")
      @req.response[:metadata].should include(:two => "TWO")
    else
      @req.response[:metadata].should == {}
    end

    # note: the duration passed in the api call is not returned (so it won't be checked)
  end
end

