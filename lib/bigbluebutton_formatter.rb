module BigBlueButton

  # Helper class to format the response hash received when the BigBlueButtonApi makes API calls
  class BigBlueButtonFormatter

    # Default formatting for all responses given by a BBB server
    def self.default_formatting(hash)

      # remove the "response" node
      response = Hash[hash[:response]].inject({}){|h,(k,v)| h[k] = v; h}

      # Adjust some values. There will always be a returncode, a message and a messageKey in the hash.
      response[:returncode] = response[:returncode].downcase == "success"                              # true instead of "SUCCESS"
      response[:messageKey] = "" if !response.has_key?(:messageKey) or response[:messageKey].empty?    # "" instead of {}
      response[:message] = "" if !response.has_key?(:message) or response[:message].empty?             # "" instead of {}

      response
    end

  end
end
