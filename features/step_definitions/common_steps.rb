def load_configs
  config_file = File.join(File.dirname(__FILE__), '..', 'config.yml')
  unless File.exist? config_file
    throw Exception.new(config_file + " does not exists. Copy the example and configure your server.")
  end
  @config = YAML.load_file(config_file)
  if ENV['SERVER']
    throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.") unless @config.has_key?(ENV['SERVER'])
    @config = @config[ENV['SERVER']]
  else
    @config = @config[@config.keys.first]
  end
  @config['bbb_version'] = '0.7' unless @config.has_key?('bbb_version')
end

When /^the default API object$/ do
  load_configs
  @api = BigBlueButton::BigBlueButtonApi.new(@config['bbb_url'], @config['bbb_salt'], @config['bbb_version'].to_s, false)
end

When /^the meeting is running$/ do
  BigBlueButtonBot.new(@api, @meeting_id)
end
