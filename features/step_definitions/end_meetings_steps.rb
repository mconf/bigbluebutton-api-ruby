When /^the method to end the meeting is called$/ do
  begin
    @req.method = :end
    @req.response = @api.end_meeting(@req.id, @req.mod_pass)
  rescue Exception => @req.exception
  end
end

When /^the response to the end method is successful and well formatted$/ do
  @req.response[:returncode].should be_true
  @req.response[:messageKey].should == "sentEndMeetingRequest"
  @req.response[:message].should_not be_empty
end

When /^the meeting should be ended$/ do
  BigBlueButtonBot.finalize # the meeting only ends when everybody closes the session
  # wait for the meeting to end
  Timeout::timeout(15) do
    running = true
    while running
      sleep 1
      meetings = @api.get_meetings
      hash = meetings[:meetings].select!{ |m| m[:meetingID] == @req.id }[0]
      running = hash[:running]
    end
  end

  @req.response =  @api.get_meeting_info(@req.id, @req.mod_pass)
  @req.response[:running].should be_false
  @req.response[:hasBeenForciblyEnded].should be_true
end

When /^the flag hasBeenForciblyEnded should be set$/ do
  @req.response[:hasBeenForciblyEnded].should be_true
end
