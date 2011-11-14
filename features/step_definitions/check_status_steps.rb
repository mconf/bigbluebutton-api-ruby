When /^the method isMeetingRunning informs that the meeting is running$/ do
  @response = @api.is_meeting_running?(@meeting_id)
  @response.should be_true
end

When /^the method isMeetingRunning informs that the meeting is not running$/i do
  @response = @api.is_meeting_running?(@meeting_id)
  @response.should be_false
end

When /^that (\d+) meetings were created$/ do |count|
  steps %Q{ When the default API object }

  @meeting_ids = []
  @moderator_passwords = []
  count.to_i.times do
    id = Forgery(:basic).random_name("test-check-status")
    pass = Forgery(:basic).password
    @meeting_ids << id
    @moderator_passwords << pass
    @api.create_meeting(id, id, { :moderatorPW => pass })
  end
end

When /^calling the method get_meetings$/ do
  @response = @api.get_meetings
end

When /^calling the method get_meeting_info$/ do
  @response = @api.get_meeting_info(@meeting_id, @moderator_password)
end

When /^these meetings should be listed in the response with proper information$/ do
  @response[:meetings].size.should >= @meeting_ids.size
  @meeting_ids.each do |id|
    found = @response[:meetings].reject{ |m| m[:meetingID] != id }
    found.should_not be_nil
    found.size.should == 1

    found = found[0]
    found[:attendeePW].should be_a(String)
    found[:attendeePW].should_not be_empty
    found[:moderatorPW].should be_a(String)
    found[:moderatorPW].should_not be_empty
    found[:hasBeenForciblyEnded].should be_false
    found[:running].should be_false
    if @api.version >= "0.8"
      found[:meetingName].should == id
      found[:createTime].should be_a(Numeric)
    end
  end
end

When /^it shows all the information of the meeting that was created$/ do
  pending
  # steps %Q{ When it is configured with the parameters used in the creation }
end
