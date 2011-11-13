When /^that the method to create a meeting was called$/ do
  @meeting_id = Forgery(:basic).random_name("test-end")
  @moderator_password = Forgery(:basic).password
  @response = @api.create_meeting(@meeting_id, @meeting_id, { :moderatorPW => @moderator_password })
end

When /^the method to end the meeting is called$/ do
  @response = @api.end_meeting(@meeting_id, @moderator_password)
end

When /^the response to the call "end" is successful and well formatted$/ do
  @response[:returncode].should be_true
  @response[:messageKey].should == "sentEndMeetingRequest"
  @response[:message].should_not be_empty
end

When /^the meeting should be ended$/ do
  BigBlueButtonBot.finalize # the meeting only ends when everybody closes the session
  # wait for the meeting to end
  Timeout::timeout(15) do
    running = true
    while running
      sleep 1
      meetings = @api.get_meetings
      hash = meetings[:meetings].select!{ |m| m[:meetingID] == @meeting_id }[0]
      running = hash[:running]
    end
  end

  @response =  @api.get_meeting_info(@meeting_id, @moderator_password)
  @response[:running].should be_false
  @response[:hasBeenForciblyEnded].should be_true
end
