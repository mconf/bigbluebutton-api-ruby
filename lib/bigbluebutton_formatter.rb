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

    # converts a value in the @hash to int
    def to_int(key)
      unless @hash.has_key?(key)
        0
      else
        @hash[key] = @hash[key].to_i rescue 0
      end
    end

    # converts a value in the @hash to string
    def to_string(key)
      @hash[key] = @hash[key].to_s
    end

    # converts a value in the @hash to DateTime
    def to_datetime(key)
      unless @hash.has_key?(key) and @hash[key]
        nil
      else
        # BBB >= 0.8 uses the unix epoch for all time related values
        # older versions use strings

        # a number but in a String class
        if (@hash[key].class == String && @hash[key].to_i.to_s == @hash[key])
          value = @hash[key].to_i
        else
          value = @hash[key]
        end

        if value.is_a?(Numeric)
          result = value == 0 ? nil : DateTime.parse(Time.at(value/1000.0).to_s)
        else
          if value.downcase == "null"
            result = nil
          else
            # note: just in case the value comes as a string in the format: "Thu Sep 01 17:51:42 UTC 2011"
            result = DateTime.parse(value)
          end
        end

        @hash[key] = result
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
      response = @hash

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
      f.to_string(:meetingName)
      f.to_string(:moderatorPW)
      f.to_string(:attendeePW)
      f.to_boolean(:hasBeenForciblyEnded)
      f.to_boolean(:running)
      f.to_int(:createTime) if meeting.has_key?(:createTime)
      f.to_string(:dialNumber)
      f.to_int(:voiceBridge)
      f.to_int(:participantCount)
      f.to_int(:listenerCount)
      f.to_int(:videoCount)
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
      if rec[:playback] and rec[:playback][:format]
        if rec[:playback][:format].is_a?(Hash)
          f2 = BigBlueButtonFormatter.new(rec[:playback][:format])
          f2.to_int(:length)
        elsif rec[:playback][:format].is_a?(Array)
          rec[:playback][:format].each do |format|
            f2 = BigBlueButtonFormatter.new(format)
            f2.to_int(:length)
          end
        end
      end
      if rec[:metadata]
        rec[:metadata].each do |key, value|
          if value.nil? or value.empty? or value.split.empty?
            # removes any no {}s, []s, or " "s, should always be empty string
            rec[:metadata][key] = ""
          end
        end
      end
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
    #   # Hash:
    #   { :name => "Test", :attendees => {} }
    #   # Result:
    #   { :name => "Test", :attendees => [] }
    #
    #   # Hash:
    #   { :name => "Test", :attendees => { :attendee => { :name => "attendee1" } } }
    #   # Result:
    #   { :name => "Test", :attendees => [ { :name => "attendee1" } ] }
    #
    def flatten_objects(first, second)
      if !@hash[first] or @hash[first].empty?
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
