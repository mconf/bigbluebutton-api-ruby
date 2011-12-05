Before do
  # stores the global configurations in variables that are easier to access
  BigBlueButton::Features::Configs.load
  @config = BigBlueButton::Features::Configs.cfg
  @config_server = BigBlueButton::Features::Configs.cfg_server
  @req = BigBlueButton::Features::Configs.req
end

After do |scenario|
  BigBlueButtonBot.finalize
end
