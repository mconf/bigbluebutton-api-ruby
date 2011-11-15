When /^the create method is called with all the optional arguments$/i do
  steps %Q{ When that a meeting was created with all the optional arguments }
end

When /^the create method is called with no optional argument$/i do
  steps %Q{ When the default API object }
  steps %Q{ When that a meeting was created }
end

When /^the create method is called with a duplicated meeting id$/ do
  steps %Q{ When the default API object }

  @req = TestApiRequest.new
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
  steps %Q{ When the default API object }

  @req = TestApiRequest.new
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

When /^the response to the create method is successful and well formatted$/ do
  @req.response[:returncode].should be_true
  @req.response[:meetingID].should == @req.id
  @req.response[:hasBeenForciblyEnded].should be_false
  @req.response[:messageKey].should == ""
  @req.response[:message].should == ""

  if @req.opts.has_key?(:attendeePW)
    @req.response[:attendeePW].should == @req.opts[:attendeePW]
  else # auto generated password
    @req.response[:attendeePW].should be_a(String)
    @req.response[:attendeePW].should_not be_empty
    @req.opts[:attendeePW] = @req.response[:attendeePW]
  end
  if @req.opts.has_key?(:moderatorPW)
    @req.response[:moderatorPW].should == @req.opts[:moderatorPW]
  else # auto generated password
    @req.response[:moderatorPW].should be_a(String)
    @req.response[:moderatorPW].should_not be_empty
    @req.opts[:moderatorPW] = @req.response[:moderatorPW]
  end

  if @api.version >= "0.8"
    @req.response[:createTime].should be_a(Numeric)
  end
end

When /^the meeting exists in the server$/ do
  @req.response = @api.get_meetings
  @req.response[:meetings].reject!{ |m| m[:meetingID] != @req.id }
  @req.response[:meetings].count.should == 1
end
