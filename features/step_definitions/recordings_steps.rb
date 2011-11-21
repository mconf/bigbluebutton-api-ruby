When /^the user creates a meeting with the record flag$/ do
  steps %Q{ When the default BigBlueButton server }

  @req.id = Forgery(:basic).random_name("test-recordings")
  @req.name = @req.id
  @req.method = :create
  @req.opts = { :record => true }
  @req.response = @api.create_meeting(@req.id, @req.name, @req.opts)
  @req.mod_pass = @req.response[:moderatorPW]
end

When /^the meeting is set to be recorded$/ do
  @req.response = @api.get_meeting_info(@req.id, @req.mod_pass)
  @req.response[:returncode].should be_true
  @req.response[:recording].should be_true
end

When /^the user creates a meeting without the record flag$/ do
  steps %Q{ When the default BigBlueButton server }

  @req.id = Forgery(:basic).random_name("test-recordings")
  @req.name = @req.id
  @req.method = :create
  @req.opts = {}
  @req.response = @api.create_meeting(@req.id, @req.name)
  @req.mod_pass = @req.response[:moderatorPW]
end

When /^the meeting is not set to be recorded$/i do
  @req.response = @api.get_meeting_info(@req.id, @req.mod_pass)
  @req.response[:returncode].should be_true
  @req.response[:recording].should be_false
end

When /^the user calls the get_recordings method$/ do
  @req.method = :get_recordings
  @req.response = @api.get_recordings
end
