require 'net/http'
require 'cgi'
require 'rexml/document'
require 'digest/sha1'
require 'rubygems'
require 'nokogiri'
require 'hash_to_xml'
require 'bigbluebutton_exception'
require 'bigbluebutton_formatter'
require 'bigbluebutton_modules'

module BigBlueButton

  # This class provides access to the BigBlueButton API. For more details see README.rdoc.
  #
  # Sample usage of the API is as follows:
  # 1. Create a meeting with create_meeting;
  # 2. Redirect a user to the URL returned by join_meeting_url;
  # 3. Get information about the meetings with get_meetings and get_meeting_info;
  # 4. To force meeting to end, call end_meeting .
  #
  # Important info about the data returned by the methods:
  # * The XML returned by BBB is converted to a Hash. See individual method's documentation for examples.
  # * Three values will *always* exist in the hash:
  #   * :returncode (boolean)
  #   * :messageKey (string)
  #   * :message (string)
  # * Some of the values returned by BBB are converted to better represent the data. Some of these are listed
  #   bellow. They will *always* have the type informed:
  #   * :meetingID (string)
  #   * :attendeePW (string)
  #   * :moderatorPW (string)
  #   * :running (boolean)
  #   * :hasBeenForciblyEnded (boolean)
  #   * :endTime and :startTime (DateTime or nil)
  #
  class BigBlueButtonApi

    attr_accessor :url, :supported_versions, :salt, :version, :debug, :timeout

    # Initializes an instance
    # url::       URL to a BigBlueButton server (e.g. http://demo.bigbluebutton.org/bigbluebutton/api)
    # salt::      Secret salt for this server
    # version::   API version: 0.7 (valid for 0.7, 0.71 and 0.71a)
    def initialize(url, salt, version='0.7', debug=false)
      @supported_versions = ['0.7', '0.8']
      @url = url
      @salt = salt
      @debug = debug
      @timeout = 10 # default timeout for api requests

      @version = version || get_api_version
      unless @supported_versions.include?(@version)
        raise BigBlueButtonException.new("BigBlueButton error: Invalid API version #{version}. Supported versions: #{@supported_versions.join(', ')}")
      end

      puts "BigBlueButtonAPI: Using version #{@version}" if @debug
    end


    #
    # API calls since 0.7
    #


    # Creates a new meeting. Returns the hash with the response or
    # throws BigBlueButtonException on failure.
    # meeting_name (string)::           Name for the meeting
    # meeting_id (string, integer)::    Unique identifier for the meeting
    # options (Hash)::                  Hash with optional parameters. The accepted parameters are:
    #                                   moderatorPW (string, int), attendeePW (string, int), welcome (string),
    #                                   dialNumber (int), logoutURL (string), maxParticipants (int),
    #                                   voiceBridge (int), record (boolean), duration (int) and "meta" parameters
    #                                   (usually strings). If a parameter passed in the hash is not supported it will
    #                                   simply be discarded. For details about each see BBB API docs.
    # modules (BigBlueButtonModules)::  Configuration for the modules. The modules are sent as an xml and the
    #                                   request will use an HTTP POST instead of GET. Currently only the
    #                                   "presentation" module is available. Only used for version > 0.8.
    #                                   See usage examples below.
    #
    # === Example
    #
    #   options = { :moderatorPW => "123", :attendeePW => "321", :welcome => "Welcome here!",
    #               :dialNumber => 5190909090, :logoutURL => "http://mconf.org", :maxParticipants => 25,
    #               :voiceBridge => 76543, :record => "true", :duration => 0, :meta_category => "Remote Class" }
    #   create_meeting("My Meeting", "my-meeting", options)
    #
    # === Example with modules (see BigBlueButtonModules docs for more)
    #
    #   modules = BigBlueButton::BigBlueButtonModules.new
    #   modules.add_presentation(:url, "http://www.samplepdf.com/sample.pdf")
    #   modules.add_presentation(:url, "http://www.samplepdf.com/sample2.pdf")
    #   modules.add_presentation(:file, "presentations/class01.ppt")
    #   modules.add_presentation(:base64, "JVBERi0xLjQKJ....[clipped here]....0CiUlRU9GCg==", "first-class.pdf")
    #   create_meeting("My Meeting", "my-meeting", nil, modules)
    #
    # === Example response for 0.7
    #
    # On successful creation:
    #
    #   {
    #    :returncode => true, :meetingID => "test",
    #    :attendeePW => "1234", :moderatorPW => "4321", :hasBeenForciblyEnded => false,
    #    :messageKey => "", :message => ""
    #   }
    #
    # Meeting that was forcibly ended:
    #
    #   {
    #    :returncode => true, :meetingID => "test",
    #    :attendeePW => "1234", :moderatorPW => "4321", :hasBeenForciblyEnded => true,
    #    :messageKey => "duplicateWarning",
    #    :message => "This conference was already in existence and may currently be in progress."
    #   }
    #
    # === Example response for 0.8
    #
    #   {
    #    :returncode => true, :meetingID => "Test", :createTime => 1308591802,
    #    :attendeePW => "1234", :moderatorPW => "4321", :hasBeenForciblyEnded => false,
    #    :messageKey => "", :message => ""
    #   }
    #
    def create_meeting(meeting_name, meeting_id, options={}, modules=nil)
      valid_options = [:moderatorPW, :attendeePW, :welcome, :dialNumber, :logoutURL,
                       :maxParticipants, :voiceBridge]

      selected_opt = options.clone
      if @version >= "0.8"
        # v0.8 added "record", "duration" and "meta_" parameters
        valid_options += [:record, :duration]
        selected_opt.reject!{ |k,v| !valid_options.include?(k) and !(k.to_s =~ /^meta_.*$/) }
        selected_opt[:record] = selected_opt[:record].to_s if selected_opt.has_key?(:record)
      else
        selected_opt.reject!{ |k,v| !valid_options.include?(k) }
      end
      params = { :name => meeting_name, :meetingID => meeting_id }.merge(selected_opt)

      # with modules we send a post request (only for >= 0.8)
      if modules and @version >= "0.8"
        response = send_api_request(:create, params, modules.to_xml)
      else
        response = send_api_request(:create, params)
      end

      formatter = BigBlueButtonFormatter.new(response)
      formatter.to_string(:meetingID)
      formatter.to_string(:moderatorPW)
      formatter.to_string(:attendeePW)
      formatter.to_boolean(:hasBeenForciblyEnded)
      if @version >= "0.8"
        formatter.to_int(:createTime)
      end

      response
    end

    # Ends an existing meeting. Throws BigBlueButtonException on failure.
    # meeting_id (string, int)::          Unique identifier for the meeting
    # moderator_password (string, int)::  Moderator password
    #
    # === Return examples (for 0.7)
    #
    # On success:
    #
    #   {
    #    :returncode=>true, :messageKey=>"sentEndMeetingRequest",
    #    :message=>"A request to end the meeting was sent.  Please wait a few seconds, and then use the getMeetingInfo
    #               or isMeetingRunning API calls to verify that it was ended."
    #   }
    #
    def end_meeting(meeting_id, moderator_password)
      send_api_request(:end, { :meetingID => meeting_id, :password => moderator_password } )
    end

    # Returns true or false as to whether meeting is open.  A meeting is
    # only open after at least one participant has joined.
    # meeting_id (string, int)::          Unique identifier for the meeting
    def is_meeting_running?(meeting_id)
      hash = send_api_request(:isMeetingRunning, { :meetingID => meeting_id } )
      BigBlueButtonFormatter.new(hash).to_boolean(:running)
    end

    # Returns the url used to join the meeting
    # meeting_id (string, int)::   Unique identifier for the meeting
    # user_name (string)::         Name of the user
    # password (string)::          Password for this meeting - used to set the user as moderator or attendee
    # options (Hash)::             Hash with optional parameters. The accepted parameters are:
    #                              userID (string, int), webVoiceConf (string, int) and createTime (int).
    #                              For details about each see BBB API docs.
    def join_meeting_url(meeting_id, user_name, password, options={})
      valid_options = [:userID, :webVoiceConf]
      valid_options += [:createTime] if @version >= "0.8"
      options.reject!{ |k,v| !valid_options.include?(k) }

      params = { :meetingID => meeting_id, :password => password, :fullName => user_name }.merge(options)

      get_url(:join, params)
    end

    # Warning: As of this version of the gem, this call does not work
    # (instead of returning XML response, it should join the meeting).
    #
    # Joins a user into the meeting using an API call, instead of
    # directing the user's browser to moderator_url or attendee_url
    # (note: this will still be required however to actually use bbb).
    # Returns the URL a user can use to enter this meeting.
    # meeting_id (string, int)::  Unique identifier for the meeting
    # user_name (string)::        Name of the user
    # password (string, int)::    Moderator or attendee password for this meeting
    # options (Hash)::             Hash with optional parameters. The accepted parameters are:
    #                              userID (string, int), webVoiceConf (string, int) and createTime (int).
    #                              For details about each see BBB API docs.
    def join_meeting(meeting_id, user_name, password, options={})
      valid_options = [:userID, :webVoiceConf]
      valid_options += [:createTime] if @version >= "0.8"
      options.reject!{ |k,v| !valid_options.include?(k) }

      params = { :meetingID => meeting_id, :password => password, :fullName => user_name }.merge(options)

      send_api_request(:join, params)
    end

    # Returns a hash object containing the meeting information.
    # See the API documentation for details on the return XML
    # (http://code.google.com/p/bigbluebutton/wiki/API).
    #
    # meeting_id (string, int)::  Unique identifier for the meeting
    # password (string, int)::    Moderator password for this meeting
    #
    # === Example responses for 0.7
    #
    # With attendees:
    #
    #   {
    #    :returncode=>true, :meetingID=>"bigbluebutton-api-ruby-test", :attendeePW=>"1234", :moderatorPW=>"4321", :running=>true,
    #    :hasBeenForciblyEnded=>false, :startTime=>DateTime("Wed Apr 06 17:09:57 UTC 2011"), :endTime=>nil, :participantCount=>4, :moderatorCount=>2,
    #    :attendees => [
    #      {:userID=>"ndw1fnaev0rj", :fullName=>"House M.D.", :role=>:moderator},
    #      {:userID=>"gn9e22b7ynna", :fullName=>"Dexter Morgan", :role=>:moderator},
    #      {:userID=>"llzihbndryc3", :fullName=>"Cameron Palmer", :role=>:viewer},
    #      {:userID=>"rbepbovolsxt", :fullName=>"Trinity", :role=>:viewer}
    #    ], :messageKey=>"", :message=>""
    #   }
    #
    # Without attendees (not started):
    #
    #   {
    #    :returncode=>true, :meetingID=>"bigbluebutton-api-ruby-test", :attendeePW=>"1234", :moderatorPW=>"4321", :running=>false,
    #    :hasBeenForciblyEnded=>false, :startTime=>nil, :endTime=>nil, :participantCount=>0, :moderatorCount=>0,
    #    :attendees=>[], :messageKey=>"", :message=>""
    #   }
    #
    # === Example responses for 0.8
    # TODO: Example with metadata
    #
    #   {
    #    :returncode => true, :meetingID => "test", :createTime => 1315254777880, :attendeePW => "1234",
    #    :moderatorPW => "4321", :running => false, :hasBeenForciblyEnded => false, :startTime => nil,
    #    :endTime => nil, :participantCount => 0, :moderatorCount => 0,
    #    :attendees => [], :messageKey => "", :message => ""
    #   }
    def get_meeting_info(meeting_id, password)
      response = send_api_request(:getMeetingInfo, { :meetingID => meeting_id, :password => password } )

      formatter = BigBlueButtonFormatter.new(response)
      formatter.flatten_objects(:attendees, :attendee)
      response[:attendees].each { |a| BigBlueButtonFormatter.format_attendee(a) }

      formatter.to_string(:meetingID)
      formatter.to_string(:moderatorPW)
      formatter.to_string(:attendeePW)
      formatter.to_boolean(:hasBeenForciblyEnded)
      formatter.to_boolean(:running)
      formatter.to_datetime(:startTime)
      formatter.to_datetime(:endTime)
      if @version >= "0.8"
        formatter.to_string(:meetingName)
        formatter.to_int(:participantCount)
        formatter.to_int(:maxUsers)
        formatter.to_int(:voiceBridge)
        formatter.to_int(:createTime)
        formatter.to_boolean(:recording)
      end

      response
    end

    # Returns a hash object containing information about the meetings currently existent in the BBB
    # server, either they are running or not.
    #
    # === Example responses for 0.7
    #
    # Server with one or more meetings:
    #
    #   { :returncode => true,
    #     :meetings => [
    #       {:meetingID=>"Demo Meeting", :attendeePW=>"ap", :moderatorPW=>"mp", :hasBeenForciblyEnded=>false, :running=>true},
    #       {:meetingID=>"I was ended Meeting", :attendeePW=>"pass", :moderatorPW=>"pass", :hasBeenForciblyEnded=>true, :running=>false}
    #     ],
    #    :messageKey=>"", :message=>""
    #   }
    #
    # Server with no meetings:
    #
    #   {:returncode=>true, :meetings=>[], :messageKey=>"noMeetings", :message=>"no meetings were found on this server"}
    #
    def get_meetings
      response = send_api_request(:getMeetings, { :random => rand(9999999999) } )

      formatter = BigBlueButtonFormatter.new(response)
      formatter.flatten_objects(:meetings, :meeting)
      response[:meetings].each { |m| BigBlueButtonFormatter.format_meeting(m) }
      response
    end

    # Returns the API version (as string) of the associated server. This actually returns
    # the version returned by the BBB server, and not the version set by the user in
    # the initialization of this object.
    def get_api_version
      response = send_api_request(:index)
      response[:returncode] ? response[:version].to_s : ""
    end



    #
    # API calls since 0.8
    #

    # Retrieves the recordings that are available for playback for a given meetingID (or set of meeting IDs).
    # options (Hash)::                Hash with optional parameters. The accepted parameters are:
    #                                 :meetingID (string, Array). For details about each see BBB API docs.
    #                                 Any of the following values are accepted for :meetingID :
    #                                   :meetingID => "id1"
    #                                   :meetingID => "id1,id2,id3"
    #                                   :meetingID => ["id1"]
    #                                   :meetingID => ["id1", "id2", "id3"]
    #
    # === Example responses
    # TODO: this example is not accurate yet
    #
    #   { :returncode => true,
    #     :recording => [
    #       { :recordID => "183f0bf3a0982a127bdb8161-1308597520", :meetingID => "CS101",
    #         :name => "On-line session for CS 101", :published => false,
    #         :startTime => DateTime("Thu Mar 04 14:05:56 UTC 2010"),
    #         :endTime => DateTime("Thu Mar 04 15:01:01 UTC 2010"),
    #         :metadata => {
    #           :title => "Test Recording", :subject => "English 232 session",
    #           :description => "First Class", :creator => "Fred Dixon",
    #           :contributor => "Richard Alam", :language => "en_US"
    #         },
    #         :playback => {
    #           :format => {
    #             :type => "simple",
    #             :url => "http://server.com/simple/playback?recordID=183f0bf3a0982a127bdb8161-1",
    #             :length => 62 }
    #         }
    #       }
    #       { :recordID => "183f0bf3a0982a127bdb8161-13085974450", :meetingID => "CS102",
    #         ...
    #         ...
    #       }
    #     ]
    #   }
    #
    def get_recordings(options={})
      raise BigBlueButtonException.new("Method only supported for versions >= 0.8") if @version < "0.8"

      valid_options = [:meetingID]
      options.reject!{ |k,v| !valid_options.include?(k) }

      # ["id1", "id2", "id3"] becomes "id1,id2,id3"
      if options.has_key?(:meetingID)
        options[:meetingID] = options[:meetingID].join(",") if options[:meetingID].instance_of?(Array)
      end

      response = send_api_request(:getRecordings, options)

      formatter = BigBlueButtonFormatter.new(response)
      formatter.flatten_objects(:recordings, :recording)
      response[:recordings].each { |r| BigBlueButtonFormatter.format_recording(r) }
      response
    end

    # Publish and unpublish recordings for a given recordID (or set of record IDs).
    # recordIDs (string, Array)::  ID or IDs of the target recordings.
    #                              Any of the following values are accepted:
    #                                "id1"
    #                                "id1,id2,id3"
    #                                ["id1"]
    #                                ["id1", "id2", "id3"]
    # publish (boolean)::          Publish or unpublish the recordings?
    #
    # === Example responses
    #
    #   { :returncode => true, :published => true }
    #
    def publish_recordings(recordIDs, publish)
      raise BigBlueButtonException.new("Method only supported for versions >= 0.8") if @version < "0.8"

      recordIDs = recordIDs.join(",") if recordIDs.instance_of?(Array) # ["id1", "id2"] becomes "id1,id2"
      response = send_api_request(:publishRecordings, { :recordID => recordIDs, :publish => publish.to_s })
    end

    # Delete one or more recordings for a given recordID (or set of record IDs).
    # recordIDs (string, Array)::  ID or IDs of the target recordings.
    #                              Any of the following values are accepted:
    #                                "id1"
    #                                "id1,id2,id3"
    #                                ["id1"]
    #                                ["id1", "id2", "id3"]
    #
    # === Example responses
    #
    #   { :returncode => true, :deleted => true }
    #
    def delete_recordings(recordIDs)
      raise BigBlueButtonException.new("Method only supported for versions >= 0.8") if @version < "0.8"

      recordIDs = recordIDs.join(",") if recordIDs.instance_of?(Array) # ["id1", "id2"] becomes "id1,id2"
      response = send_api_request(:deleteRecordings, { :recordID => recordIDs })
    end


    #
    # Helper functions
    #

    # Make a simple request to the server to test the connection.
    def test_connection
      response = send_api_request(:index)
      response[:returncode]
    end

    # API's are equal if all the following attributes are equal.
    def ==(other)
      r = true
      [:url, :supported_versions, :salt, :version, :debug].each do |param|
        r = r && self.send(param) == other.send(param)
      end
      r
    end

    # Returns the HTTP response object returned in the last API call.
    def last_http_response
      @http_response
    end

    # Formats an API call URL for the method 'method' using the parameters in 'params'.
    # method (symbol)::  The API method to be called (:create, :index, :join, and others)
    # params (Hash)::    The parameters to be passed in the URL
    def get_url(method, params={})
      if method == :index
        return @url
      end

      url = "#{@url}/#{method}?"

      # stringify and escape all params
      params.delete_if { |k, v| v.nil? } unless params.nil?
      params_string = ""
      params_string = params.map{ |k,v| "#{k}=" + CGI::escape(v.to_s) unless k.nil? || v.nil? }.join("&")

      # checksum calc
      checksum_param = params_string + @salt
      checksum_param = method.to_s + checksum_param
      checksum = Digest::SHA1.hexdigest(checksum_param)

      # final url
      url += "#{params_string}&" unless params_string.empty?
      url += "checksum=#{checksum}"
    end

    # Performs an API call.
    #
    # Throws a BigBlueButtonException if something goes wrong (e.g. server offline).
    # Also throws an exception of the request was not successful (i.e. returncode == FAILED).
    #
    # Only formats the standard values in the response (the ones that exist in all responses).
    #
    # method (symbol)::  The API method to be called (:create, :index, :join, and others)
    # params (Hash)::    The parameters to be passed in the URL
    # data (string)::    Data to be sent with the request. If set, the request will use an HTTP
    #                    POST instead of a GET and the data will be sent in the request body.
    def send_api_request(method, params={}, data=nil)
      url = get_url(method, params)

      @http_response = send_request(url, data)
      return { } if @http_response.body.empty?

      # 'Hashify' the XML
      hash = Hash.from_xml(@http_response.body)

      # simple validation of the xml body
      unless hash.has_key?(:response) and hash[:response].has_key?(:returncode)
        raise BigBlueButtonException.new("Invalid response body. Is the API URL correct? \"#{@url}\", version #{@version}")
      end

      # default cleanup in the response
      hash = BigBlueButtonFormatter.new(hash).default_formatting

      # all responses should have a returncode
      unless hash[:returncode]
        exception = BigBlueButtonException.new(hash[:message])
        exception.key = hash.has_key?(:messageKey) ? hash[:messageKey] : ""
        raise exception
      end

      hash
    end

    protected

    # :nodoc:
    # If data is set, uses a POST with data in the request body
    # Otherwise uses GET
    def send_request(url, data=nil)
      begin
        puts "BigBlueButtonAPI: URL request = #{url}" if @debug
        url_parsed = URI.parse(url)
        http = Net::HTTP.new(url_parsed.host, url_parsed.port)
        http.open_timeout = @timeout
        http.read_timeout = @timeout
        if data.nil?
          response = http.get(url_parsed.request_uri)
        else
          puts "BigBlueButtonAPI: Sending as a POST request with data.size = #{data.size}" if @debug
          opts = { 'Content-Type' => 'text/xml' }
          response = http.post(url_parsed.request_uri, data, opts)
        end
        puts "BigBlueButtonAPI: URL response = #{response.body}" if @debug

      rescue TimeoutError => error
        raise BigBlueButtonException.new("Timeout error. Your server is probably down: \"#{@url}\"")

      rescue Exception => error
        raise BigBlueButtonException.new("Connection error. Your URL is probably incorrect: \"#{@url}\"")
      end

      response
    end

  end
end


