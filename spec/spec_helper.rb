require 'forgery'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load Factories
#require 'factory_girl'
# Dir["#{ File.dirname(__FILE__)}/factories/*.rb"].each { |f| require f }


RSpec.configure do |config|
  config.mock_with :rspec
end

require "bigbluebutton_api"
