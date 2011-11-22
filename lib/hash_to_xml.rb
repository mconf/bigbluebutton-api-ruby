require 'xmlsimple'

class Hash
  class << self
    def from_xml(xml_io)
      begin
        opts = { 'ForceArray' => false, 'ForceContent' => false } # 'KeyToSymbol' => true
        hash = XmlSimple.xml_in(xml_io, opts)
        return symbolize_keys(hash)
      rescue Exception => e
        raise BigBlueButton::BigBlueButtonException.new("Impossible to convert XML to hash. Error: #{e.message}")
      end
    end

    def symbolize_keys arg
      case arg
      when Array
        arg.map {  |elem| symbolize_keys elem }
      when Hash
        Hash[
             arg.map {  |key, value|
               k = key.is_a?(String) ? key.to_sym : key
               v = symbolize_keys value
               [k,v]
             }]
      else
        arg
      end
    end

  end
end
