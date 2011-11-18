When /^the method to end the meeting is called$/ do
  begin
    @req.method = :end
    @req.response = @api.end_meeting(@req.id, @req.mod_pass)
  rescue Exception => @req.exception
  end
end

When /^the meeting should be ended$/ do
  # the meeting only ends when everybody closes the session
  BigBlueButtonBot.finalize

  # wait for the meeting to end
  Timeout::timeout(@config['timeout_ending']) do
    running = true
    while running
      sleep 1
      response = @api.get_meetings
      selected = response[:meetings].reject!{ |m| m[:meetingID] != @req.id }
      running = selected[0][:running] unless selected.nil?
    end
  end

end

When /^the flag hasBeenForciblyEnded should be set$/ do
  @req.response[:hasBeenForciblyEnded].should be_true
end

When /^the information returned by get_meeting_info is correct$/ do
  # check only what is different in a meeting that WAS ENDED
  # the rest is checked in other scenarios

  @req.response = @api.get_meeting_info(@req.id, @req.mod_pass)
  @req.response[:running].should be_false
  @req.response[:hasBeenForciblyEnded].should be_true
  @req.response[:participantCount].should == 0
  @req.response[:moderatorCount].should == 0
  @req.response[:attendees].should == []

  # start and end times that should be within 2 hours from now
  @req.response[:startTime].should be_a(DateTime)
  @req.response[:startTime].should < DateTime.now
  @req.response[:startTime].should >= DateTime.now - (2/24.0)
  @req.response[:endTime].should be_a(DateTime)
  @req.response[:endTime].should < DateTime.now
  @req.response[:endTime].should >= DateTime.now - (2/24.0)
  @req.response[:endTime].should > @req.response[:startTime]
end
