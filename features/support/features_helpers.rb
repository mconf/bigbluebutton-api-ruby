module BigBlueButton
  module Features

    # Test object that stores information about an API request
    class APIRequest
      attr_accessor :opts       # options hash
      attr_accessor :id         # meetind id
      attr_accessor :mod_pass   # moderator password
      attr_accessor :name       # meeting name
      attr_accessor :method     # last api method called
      attr_accessor :response   # last api response
      attr_accessor :exception  # last exception
    end

    # Global configurations
    module Configs
      class << self
        attr_accessor :cfg           # configuration file
        attr_accessor :cfg_server    # shortcut to the choosen server configs
        attr_accessor :req           # api request

        def initialize_cfg
          config_file = File.join(File.dirname(__FILE__), '..', 'config.yml')
          unless File.exist? config_file
            throw Exception.new(config_file + " does not exists. Copy the example and configure your server.")
          end
          config = YAML.load_file(config_file)
          config
        end

        def initialize_cfg_server
          if ENV['SERVER']
            unless self.cfg['servers'].has_key?(ENV['SERVER'])
              throw Exception.new("Server #{ENV['SERVER']} does not exists in your configuration file.")
            end
            server = self.cfg['servers'][ENV['SERVER']]
          else
            server = self.cfg['servers'].first[1]
          end
          server['version'] = '0.81' unless server.has_key?('version')
          server
        end

        def load
          self.cfg = initialize_cfg
          self.cfg_server = initialize_cfg_server
          self.req = BigBlueButton::Features::APIRequest.new
        end

      end
    end

  end
end
