Then /^the method to create a meeting is called with meeting ID "(.*)"$/ do |id|
  @meeting_id = Forgery(:basic).random_name(id)
  @options = { :moderatorPW => Forgery(:basic).password,
               :attendeePW => Forgery(:basic).password,
               :welcome => Forgery(:lorem_ipsum).words(10),
               :dialNumber => Forgery(:basic).number(:at_most => 999999999).to_s,
               :logoutURL => Forgery(:internet).url,
               :voiceBridge => Forgery(:basic).number(:at_least => 70000, :at_most => 79999),
               :maxParticipants => Forgery(:basic).number }
  # TODO: more options for 0.8 - metadata, etc.
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
    @response[:createTime].should be_a(Numeric)
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
    @response[:recording].should be_false
    @response[:maxUsers].should == @options[:maxParticipants]
    @response[:createTime].should be_a(Numeric)
    @response[:metadata].should == {}
    @response[:voiceBridge].should == @options[:voiceBridge]
  end
end
