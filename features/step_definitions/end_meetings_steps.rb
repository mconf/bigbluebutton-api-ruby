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
      selected = response[:meetings].select!{ |m| m[:meetingID] == @req.id }
      running = selected[0][:running] unless selected.nil?
    end
  end

  @req.response =  @api.get_meeting_info(@req.id, @req.mod_pass)
  @req.response[:running].should be_false
  @req.response[:hasBeenForciblyEnded].should be_true
end

When /^the flag hasBeenForciblyEnded should be set$/ do
  @req.response[:hasBeenForciblyEnded].should be_true
end
