require 'uri'

Then /^that the method to create a meeting was called with meeting ID "(.*)"$/ do |id|
  @meeting_id = Forgery(:basic).random_name(id)
  @moderator_password = Forgery(:basic).password
  @response = @api.create_meeting(@meeting_id, @meeting_id, { :moderatorPW => @moderator_password })
end

Then /^the meeting is running$/ do
  uri = URI.parse(@api.url)
  uri_s = uri.scheme + "://" + uri.host
  uri_s = uri_s + ":" + uri.port.to_s if uri.port != uri.default_port
  BigBlueButtonBot.new(uri_s, @meeting_id)
end

Then /^the method to end the meeting is called$/ do
  @response = @api.end_meeting(@meeting_id, @moderator_password)
end

Then /^the flag hasBeenForciblyEnded should be set$/ do
  @response[:hasBeenForciblyEnded].should be_true
end

