When /^the user creates a meeting pre\-uploading the following presentations:$/ do |table|
  modules = BigBlueButton::BigBlueButtonModules.new
  table.hashes.each do |pres|
    modules.add_presentation(pres["type"].to_sym, pres["presentation"])
  end

  @req.id = Forgery(:basic).random_name("test-pre-upload")
  @req.name = @req.id
  @req.method = :create
  @req.opts = {}
  @req.response = @api.create_meeting(@req.id, @req.name, @req.opts, modules)
  @req.mod_pass = @req.response[:moderatorPW]
end
