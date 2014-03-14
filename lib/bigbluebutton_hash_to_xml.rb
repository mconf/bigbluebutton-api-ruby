require 'xmlsimple'

module BigBlueButton
  class BigBlueButtonHash < Hash
    class << self
      def from_xml(xml_io)
        begin
          # we'll not use 'KeyToSymbol' because it doesn't symbolize the keys for node attributes
          opts = { 'ForceArray' => false, 'ForceContent' => false } #
          hash = XmlSimple.xml_in(xml_io, opts)
          return symbolize_keys(hash)
        rescue Exception => e
          raise BigBlueButtonException.new("Impossible to convert XML to hash. Error: #{e.message}")
        end
      end

      def symbolize_keys(arg)
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
end
