require "xmlsimple"

module BigBlueButton

  # A helper class to work with config.xml files.
  # You set an xml file on it (usually obtained via BigBlueButtonApi#get_default_config_xml),
  # use it to modify this xml, and then get the new xml from this class (usually to set in the
  # server using BigBlueButtonApi#set_config_xml).
  #
  # === Usage example:
  #
  #   xml = api.get_default_config_xml
  #   config_xml = BigBlueButton::BigBlueButtonConfigXml.new(xml)
  #
  #   # change the xml a bit
  #   config_xml.set_attribute("skinning", "enabled", "false", false)
  #   config_xml.set_attribute("layout", "defaultLayout", "Webinar", false)
  #   config_xml.set_attribute("layout", "showLayoutTools", "false", false)
  #
  #   # set the new xml in the server
  #   api.set_config_xml("meeting-id", config_xml)
  #
  class BigBlueButtonConfigXml

    attr_accessor :xml

    def initialize(xml)
      @original_string = nil
      @xml = nil
      unless xml.nil?
        opts = { 'ForceArray' => false, 'KeepRoot' => true }
        begin
          @xml = XmlSimple.xml_in(xml, opts)
          @original_string = self.as_string.clone
        rescue Exception => e
          raise BigBlueButton::BigBlueButtonException.new("Error parsing the config XML. Error: #{e.message}")
        end
      end
    end

    def get_attribute(finder, attr_name, is_module=true)
      if is_module
        tag = find_module(finder)
      else
        tag = find_tag(finder)
      end
      if tag
        find_attribute(tag, attr_name)
      else
        nil
      end
    end

    def set_attribute(finder, attr_name, value, is_module=true)
      if is_module
        tag = find_module(finder)
      else
        tag = find_tag(finder)
      end
      if tag
        attr = find_attribute(tag, attr_name)
        if attr
          # saves always as string
          tag[attr_name] = value.is_a?(String) ? value : value.to_s
        else
          nil
        end
      else
        nil
      end
    end

    def as_string
      XmlSimple.xml_out(@xml, { 'RootName' => nil, 'XmlDeclaration' => false, 'NoIndent' => true })
    end

    def is_modified?
      @xml and
        self.as_string != @original_string
    end

    protected

    def find_module(module_name)
      if xml_has_modules
        modules = @xml["config"]["modules"]["module"]
        modules = [modules] unless modules.is_a?(Array)
        modules.each do |mod|
          if mod["name"] == module_name
            return mod
          end
        end
      end
      nil
    end

    def find_tag(name)
      if xml_has_config
        @xml["config"][name]
      end
    end

    def find_attribute(mod, attr_name)
      if mod and mod[attr_name]
        return mod[attr_name]
      else
        return nil
      end
    end

    def xml_has_modules
      xml_has_config and
        @xml["config"]["modules"] and
        @xml["config"]["modules"]["module"]
    end

    def xml_has_config
      @xml and @xml["config"]
    end

  end

end
