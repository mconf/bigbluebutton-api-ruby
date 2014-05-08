require "xmlsimple"

module BigBlueButton

  # A helper class to work with layout definition files.
  # You set an xml file on it (usually obtained from a property of in the XML obtained from
  # BigBlueButtonApi#get_default_config_xml), use it to work with the layouts, and then get
  # the new xml from this class.
  #
  # === Usage example:
  #
  #   xml = api.get_default_config_xml
  #   config_xml = BigBlueButton::BigBlueButtonConfigXml.new(xml)
  #   url = config_xml.get_attribute("LayoutModule", "layoutConfig", true)
  #   # send a request to 'url' to fetch the xml file into 'response'
  #
  #   layout_config = BigBlueButton::BigBlueButtonConfigLayout.new(response)
  #   layout_config.get_available_layouts
  #
  class BigBlueButtonConfigLayout

    attr_accessor :xml

    # xml (string)::  The XML that has the definition of all layouts, usually fetched from
    #                 the web conference server.
    def initialize(xml)
      @xml = nil
      opts = { 'ForceArray' => false, 'KeepRoot' => true }
      begin
        @xml = XmlSimple.xml_in(xml, opts)
      rescue Exception => e
        raise BigBlueButton::BigBlueButtonException.new("Error parsing the layouts XML. Error: #{e.message}")
      end
    end

    # Returns an array with the name of each layout available in the XML.
    # Will return only unique names, ordered the way they are ordered in the XML.
    # Returns nil if the XML is not properly formatted and an empty
    # array if there are no layouts in the file.
    def get_available_layouts
      if xml_has_layouts
        xml["layouts"]["layout"].map{ |l| l["name"] }.uniq
      else
        nil
      end
    end

    protected

    def xml_has_layouts
      @xml and @xml["layouts"] and @xml["layouts"]["layout"]
    end

  end

end
