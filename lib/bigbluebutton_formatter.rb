module BigBlueButton

  # Helper class to format the response hash received when the BigBlueButtonApi makes API calls
  class BigBlueButtonFormatter
    attr_accessor :hash

    def initialize(hash)
      @hash = hash || {}
    end

    # converts a value in the @hash to boolean
    def to_boolean(key)
      unless @hash.has_key?(key)
        false
      else
        @hash[key] = @hash[key].downcase == "true"
      end
    end

    # converts a value in the @hash to string
    def to_string(key)
      @hash[key] = @hash[key].to_s
    end

    # converts a value in the @hash to DateTime
    def to_datetime(key)
      unless @hash.has_key?(key)
        nil
      else
        @hash[key] = @hash[key].downcase == "null" ? nil : DateTime.parse(@hash[key])
      end
    end

    # converts a value in the @hash to a symbol
    def to_sym(key)
      unless @hash.has_key?(key)
        ""
      else
        if @hash[key].instance_of?(Symbol)
          @hash[key]
        elsif @hash[key].empty?
          ""
        else
          @hash[key] = @hash[key].downcase.to_sym
        end
      end
    end

    # Default formatting for all responses given by a BBB server
    def default_formatting

      # remove the "response" node
      response = Hash[@hash[:response]].inject({}){|h,(k,v)| h[k] = v; h}

      # Adjust some values. There will always be a returncode, a message and a messageKey in the hash.
      response[:returncode] = response[:returncode].downcase == "success"                              # true instead of "SUCCESS"
      response[:messageKey] = "" if !response.has_key?(:messageKey) or response[:messageKey].empty?    # "" instead of {}
      response[:message] = "" if !response.has_key?(:message) or response[:message].empty?             # "" instead of {}

      @hash = response
    end

    # Default formatting for a meeting hash
    def self.format_meeting(meeting)
      f = BigBlueButtonFormatter.new(meeting)
      f.to_string(:meetingID)
      f.to_string(:moderatorPW)
      f.to_string(:attendeePW)
      f.to_boolean(:hasBeenForciblyEnded)
      f.to_boolean(:running)
      meeting
    end

    # Default formatting for an attendee hash
    def self.format_attendee(attendee)
      f = BigBlueButtonFormatter.new(attendee)
      f.to_string(:userID)
      f.to_sym(:role)
      attendee
    end

    # Default formatting for a recording hash
    def self.format_recording(rec)
      f = BigBlueButtonFormatter.new(rec)
      f.to_string(:recordID)
      f.to_string(:meetingID)
      f.to_string(:name)
      f.to_boolean(:published)
      f.to_datetime(:startTime)
      f.to_datetime(:endTime)
      rec
    end

    # Simplifies the XML-styled hash node 'first'. Its value will then always be an Array.
    #
    # For example, if the current hash is:
    #   { :name => "Test", :attendees => { :attendee => [ { :name => "attendee1" }, { :name => "attendee2" } ] } }
    #
    # Calling:
    #  flatten_objects(:attendees, :attendee)
    #
    # The hash will become:
    #   { :name => "Test", :attendees => [ { :name => "attendee1" }, { :name => "attendee2" } ] }
    #
    # Other examples:
    #
    # Hash:
    #   { :name => "Test", :attendees => {} }
    # Result:
    #   { :name => "Test", :attendees => [] }
    #
    # Hash:
    #   { :name => "Test", :attendees => { :attendee => { :name => "attendee1" } } }
    # Result:
    #   { :name => "Test", :attendees => [ { :name => "attendee1" } ] }
    #
    def flatten_objects(first, second)
      if @hash[first].empty?
        collection = []
      else
        node = @hash[first][second]
        if node.kind_of?(Array)
          collection = node
        else
          collection = []
          collection << node
        end
      end
      @hash[first] = collection
      @hash
    end

  end
end
