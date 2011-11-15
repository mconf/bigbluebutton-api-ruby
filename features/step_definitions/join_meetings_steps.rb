When /^the user tries to access the link to join the meeting as (.*)$/ do |role|
  case role.downcase.to_sym
  when :moderator
    @req.response = @api.join_meeting_url(@req.id, "any-mod", @req.mod_pass)
  when :attendee
    @req.response = @api.join_meeting_url(@req.id, "any-attendee", @req.response[:attendeePW])
  end
end

When /^he is redirected to the BigBlueButton client$/ do
  # requests the join url and expects a redirect
  uri = URI(@req.response)
  response = Net::HTTP.get_response(uri)
  response.should be_a(Net::HTTPFound)
  response.code.should == "302"

  # check redirect to the correct bbb client page
  bbb_client_url = @api.url.gsub(URI(@api.url).path, "") + "/client/BigBlueButton.html"
  response["location"].should match(/#{bbb_client_url}/)
end

When /^the user tries to access the link to join a meeting that was not created$/ do
  @req.response = @api.join_meeting_url("should-not-exist-in-server", "any", "any")
end

When /^the response is an xml with the error "(.*)"$/ do |error|
  # requests the join url and expects an ok with an xml in the response body
  uri = URI(@req.response)
  response = Net::HTTP.get_response(uri)
  response.should be_a(Net::HTTPOK)
  response.code.should == "200"
  response["content-type"].should match(/text\/xml/)
  response.body.should match(/#{error}/)
end

When /^the user tries to access the link to join the meeting using a wrong password$/ do
  @req.response = @api.join_meeting_url(@req.id, "any-attendee", @req.mod_pass + "is wrong")
end

