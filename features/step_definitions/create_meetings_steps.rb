When /^the create method is called with all the optional arguments$/i do
  steps %Q{ When that a meeting was created with all the optional arguments }
end

When /^the create method is called with no optional arguments$/i do
  steps %Q{ When the default BigBlueButton server }
  steps %Q{ When that a meeting was created }
end

When /^the create method is called with a duplicated meeting id$/ do
  steps %Q{ When the default BigBlueButton server }

  @req.id = Forgery(:basic).random_name("test-create")
  @req.name = @req.id

  # first meeting
  @req.method = :create
  @api.create_meeting(@req.id, @req.name)

  begin
    # duplicated meeting to be tested
    @req.method = :create
    @req.response = @api.create_meeting(@req.id, @req.name)
  rescue Exception => @req.exception
  end
end

When /^the create method is called$/ do
  steps %Q{ When the default BigBlueButton server }

  @req.id = Forgery(:basic).random_name("test-create")
  @req.name = @req.id
  @req.method = :create
  @req.response = @api.create_meeting(@req.id, @req.name)
  @req.mod_pass = @req.response[:moderatorPW]
end

When /^the meeting is forcibly ended$/ do
  @req.response = @api.end_meeting(@req.id, @req.mod_pass)
end

When /^the create method is called again with the same meeting id$/ do
  begin
    @req.method = :create
    @req.response = @api.create_meeting(@req.id, @req.name)
  rescue Exception => @req.exception
  end
end

When /^the meeting exists in the server$/ do
  @req.response = @api.get_meetings
  @req.response[:meetings].reject!{ |m| m[:meetingID] != @req.id }
  @req.response[:meetings].count.should == 1
end
