require 'uri'

When /^that the method to create a meeting was called with meeting ID "(.*)"$/ do |id|
  @meeting_id = Forgery(:basic).random_name(id)
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
  pending
end
