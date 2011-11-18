Before do
  # stores the global configurations in variables that are easier to access
  BigBlueButtonAPITests::Configs.load
  @config = BigBlueButtonAPITests::Configs.cfg
  @config_server = BigBlueButtonAPITests::Configs.cfg_server
  @req = BigBlueButtonAPITests::Configs.req
end

After do |scenario|
  BigBlueButtonBot.finalize
end
