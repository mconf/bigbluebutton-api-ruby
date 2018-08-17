require 'net/http'
require 'cgi'
require 'rexml/document'
require 'digest/sha1'
require 'rubygems'
require 'bigbluebutton_hash_to_xml'
require 'bigbluebutton_exception'
require 'bigbluebutton_formatter'
require 'bigbluebutton_modules'
require 'bigbluebutton_config_xml'
require 'bigbluebutton_config_layout'

module BigBlueButton

  # This class provides access to the BigBlueButton API. For more details see README.
  #
  # Sample usage of the API is as follows:
  # 1. Create a meeting with create_meeting;
  # 2. Redirect a user to the URL returned by join_meeting_url;
  # 3. Get information about the meetings with get_meetings and get_meeting_info;
  # 4. To force meeting to end, call end_meeting .
  #
  # Important info about the data returned by the methods:
  # * The XML returned by BigBlueButton is converted to a BigBlueButton::BigBlueButtonHash. See each method's documentation
  #   for examples.
  # * Three values will *always* exist in the hash:
  #   * :returncode (boolean)
  #   * :messageKey (string)
  #   * :message (string)
  # * Some of the values returned by BigBlueButton are converted to better represent the data.
  #   Some of these are listed bellow. They will *always* have the type informed:
  #   * :meetingID (string)
  #   * :attendeePW (string)
  #   * :moderatorPW (string)
  #   * :running (boolean)
  #   * :hasBeenForciblyEnded (boolean)
  #   * :endTime and :startTime (DateTime or nil)
  #
  # For more information about the API, see the documentation at:
  # * http://code.google.com/p/bigbluebutton/wiki/API
  #
  class BigBlueButtonApi

    # URL to a BigBlueButton server (e.g. http://demo.bigbluebutton.org/bigbluebutton/api)
    attr_accessor :url

    # Shared secret for this server
    attr_accessor :secret

    # API version e.g. 0.81
    attr_accessor :version

    # Flag to turn on/off debug mode
    attr_accessor :debug

    # Maximum wait time for HTTP requests (secs)
    attr_accessor :timeout

    # HTTP headers to be sent in all GET/POST requests
    attr_accessor :request_headers

    # Array with the version of BigBlueButton supported
    # TODO: do we really need an accessor? shouldn't be internal?
    attr_accessor :supported_versions

    # Initializes an instance
    # url::       URL to a BigBlueButton server (e.g. http://demo.bigbluebutton.org/bigbluebutton/api)
    # secret::    Shared secret for this server
    # version::   API version e.g. 0.81
    def initialize(url, secret, version=nil, debug=false)
      @supported_versions = ['0.8', '0.81', '0.9', '1.0']
      @url = url
      @secret = secret
      @debug = debug
      @timeout = 10         # default timeout for api requests
      @request_headers = {} # http headers sent in all requests

      version = nil if version && version.strip.empty?
      @version = nearest_version(version || get_api_version)
      unless @supported_versions.include?(@version)
        puts "BigBlueButtonAPI: detected unsupported version, using the closest one that is supported (#{@version})"
      end

      puts "BigBlueButtonAPI: Using version #{@version}" if @debug
    end

    # Creates a new meeting. Returns the hash with the response or throws BigBlueButtonException
    # on failure.
    # meeting_name (string)::           Name for the meeting
    # meeting_id (string)::             Unique identifier for the meeting
    # options (Hash)::                  Hash with additional parameters. The accepted parameters are:
    #                                   moderatorPW (string), attendeePW (string), welcome (string),
    #                                   dialNumber (int), logoutURL (string), maxParticipants (int),
    #                                   voiceBridge (int), record (boolean), duration (int), redirectClient (string),
    #                                   clientURL (string), and "meta" parameters (usually strings).
    #                                   For details about each see BigBlueButton's API docs.
    #                                   If you have a custom API with more parameters, you can simply pass them
    #                                   in this hash and they will be added to the API call.
    # modules (BigBlueButtonModules)::  Configuration for the modules. The modules are sent as an xml and the
    #                                   request will use an HTTP POST instead of GET. Currently only the
    #                                   "presentation" module is available.
    #                                   See usage examples below.
    #
    # === Example
    #
    #   options = {
    #     :attendeePW => "321",
    #     :moderatorPW => "123",
    #     :welcome => "Welcome here!",
    #     :dialNumber => 5190909090,
    #     :voiceBridge => 76543,
    #     :logoutURL => "http://mconf.org",
    #     :record => true,
    #     :duration => 0,
    #     :maxParticipants => 25,
    #     :meta_category => "Remote Class"
    #   }
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
    # === Example response for 0.81
    #
    # On successful creation:
    #
    #   {
    #     :returncode => true,
    #     :meetingID => "0c521f3d",
    #     :attendeePW => "12345",
    #     :moderatorPW => "54321",
    #     :createTime => 1389464535956,
    #     :hasBeenForciblyEnded => false,
    #     :messageKey => "",
    #     :message => ""
    #   }
    #
    # When creating a meeting that already exist:
    #
    #   {
    #     :returncode => true,
    #     :meetingID => "7a1d614b",
    #     :attendeePW => "12345",
    #     :moderatorPW => "54321",
    #     :createTime => 1389464682402,
    #     :hasBeenForciblyEnded => false,
    #     :messageKey => "duplicateWarning",
    #     :message => "This conference was already in existence and may currently be in progress."
    #   }
    #
    def create_meeting(meeting_name, meeting_id, options={}, modules=nil)
      params = { :name => meeting_name, :meetingID => meeting_id }.merge(options)

      # :record is passed as string, but we accept boolean as well
      if params[:record] and !!params[:record] == params[:record]
        params[:record] = params[:record].to_s
      end

      # with modules we send a post request
      if modules
        response = send_api_request(:create, params, modules.to_xml)
      else
        response = send_api_request(:create, params)
      end

      formatter = BigBlueButtonFormatter.new(response)
      formatter.to_string(:meetingID)
      formatter.to_string(:moderatorPW)
      formatter.to_string(:attendeePW)
      formatter.to_boolean(:hasBeenForciblyEnded)
      formatter.to_int(:createTime)

      response
    end

    # Ends an existing meeting. Throws BigBlueButtonException on failure.
    # meeting_id (string)::          Unique identifier for the meeting
    # moderator_password (string)::  Moderator password
    # options (Hash)::               Hash with additional parameters. This method doesn't accept additional
    #                                parameters, but if you have a custom API with more parameters, you
    #                                can simply pass them in this hash and they will be added to the API call.
    #
    # === Return examples (for 0.81)
    #
    # On success:
    #
    #   {
    #     :returncode=>true,
    #     :messageKey => "sentEndMeetingRequest",
    #     :message => "A request to end the meeting was sent.  Please wait a few seconds, and then use the getMeetingInfo or isMeetingRunning API calls to verify that it was ended."
    #   }
    #
    def end_meeting(meeting_id, moderator_password, options={})
      params = { :meetingID => meeting_id, :password => moderator_password }.merge(options)
      send_api_request(:end, params)
    end

    # Returns whether the meeting is running or not. A meeting is only running after at least
    # one participant has joined. Returns true or false.
    # meeting_id (string)::    Unique identifier for the meeting
    # options (Hash)::         Hash with additional parameters. This method doesn't accept additional
    #                          parameters, but if you have a custom API with more parameters, you
    #                          can simply pass them in this hash and they will be added to the API call.
    def is_meeting_running?(meeting_id, options={})
      params = { :meetingID => meeting_id }.merge(options)
      hash = send_api_request(:isMeetingRunning, params)
      BigBlueButtonFormatter.new(hash).to_boolean(:running)
    end

    # Returns a string with the url used to join the meeting
    # meeting_id (string)::   Unique identifier for the meeting
    # user_name (string)::    Name of the user
    # password (string)::     Password for this meeting - will be used to decide if the user is a
    #                         moderator or attendee
    # options (Hash)::        Hash with additional parameters. The accepted parameters are:
    #                         userID (string), webVoiceConf (string), createTime (int),
    #                         configToken (string), and avatarURL (string).
    #                         For details about each see BigBlueButton's API docs.
    #                         If you have a custom API with more parameters, you can simply pass them
    #                         in this hash and they will be added to the API call.
    def join_meeting_url(meeting_id, user_name, password, options={})
      params = { :meetingID => meeting_id, :password => password, :fullName => user_name }.merge(options)
      url, data = get_url(:join, params)
      url
    end

    # Returns a hash object containing the information of a meeting.
    #
    # meeting_id (string)::  Unique identifier for the meeting
    # password (string)::    Moderator password for this meeting
    # options (Hash)::       Hash with additional parameters. This method doesn't accept additional
    #                        parameters, but if you have a custom API with more parameters, you
    #                        can simply pass them in this hash and they will be added to the API call.
    #
    # === Example responses for 0.81
    #
    # Running with attendees and metadata:
    #
    #
    #   {
    #     :returncode => true,
    #     :meetingName => "e56ef2c5",
    #     :meetingID => "e56ef2c5",
    #     :createTime => 1389465592542,
    #     :voiceBridge => 72519,
    #     :dialNumber => "1-800-000-0000x00000#",
    #     :attendeePW => "12345",
    #     :moderatorPW => "54321",
    #     :running => true,
    #     :recording => false,
    #     :hasBeenForciblyEnded => false,
    #     :startTime => #<DateTime: 2014-01-11T16:39:58-02:00 ((2456669j,67198s,0n),-7200s,2299161j)>,
    #     :endTime => nil,
    #     :participantCount => 2,
    #     :maxUsers => 25,
    #     :moderatorCount => 1,
    #     :attendees => [
    #       { :userID => "wsfoiqtnugul", :fullName => "Cameron", :role => :viewer, :customdata => {} },
    #       { :userID => "qsaogaoqifjk", :fullName => "House", :role => :moderator, :customdata => {} }
    #     ],
    #     :metadata => {
    #       :category => "Testing",
    #       :anything => "Just trying it out"
    #     },
    #     :messageKey => "",
    #     :message => ""
    #   }
    #
    # Created but not started yet:
    #
    #   {
    #     :returncode => true,
    #     :meetingName => "fe3ea879",
    #     :meetingID => "fe3ea879",
    #     :createTime => 1389465320050,
    #     :voiceBridge => 79666,
    #     :dialNumber => "1-800-000-0000x00000#",
    #     :attendeePW => "12345",
    #     :moderatorPW => "54321",
    #     :running => false,
    #     :recording => false,
    #     :hasBeenForciblyEnded => false,
    #     :startTime => nil,
    #     :endTime => nil,
    #     :participantCount => 0,
    #     :maxUsers => 25,
    #     :moderatorCount => 0,
    #     :attendees => [],
    #     :metadata => {},
    #     :messageKey => "",
    #     :message => ""
    #   }
    #
    def get_meeting_info(meeting_id, password, options={})
      params = { :meetingID => meeting_id, :password => password }.merge(options)
      response = send_api_request(:getMeetingInfo, params)

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
      formatter.to_int(:participantCount)
      formatter.to_int(:moderatorCount)
      formatter.to_string(:meetingName)
      formatter.to_int(:maxUsers)
      formatter.to_int(:voiceBridge)
      formatter.to_int(:createTime)
      formatter.to_boolean(:recording)

      response
    end

    # Returns a hash object with information about all the meetings currently created in the
    # server, either they are running or not.
    #
    # options (Hash)::       Hash with additional parameters. This method doesn't accept additional
    #                        parameters, but if you have a custom API with more parameters, you
    #                        can simply pass them in this hash and they will be added to the API call.
    #
    # === Example responses for 0.81
    #
    # Server with one or more meetings:
    #
    #   {
    #     :returncode => true,
    #     :meetings => [
    #       { :meetingID => "e66e88a3",
    #         :meetingName => "e66e88a3",
    #         :createTime => 1389466124414,
    #         :voiceBridge => 78730,
    #         :dialNumber=>"1-800-000-0000x00000#",
    #         :attendeePW => "12345",
    #         :moderatorPW => "54321",
    #         :hasBeenForciblyEnded => false,
    #         :running => false,
    #         :participantCount => 0,
    #         :listenerCount => 0,
    #         :videoCount => 0 }
    #       { :meetingID => "8f21cc63",
    #         :meetingName => "8f21cc63",
    #         :createTime => 1389466073245,
    #         :voiceBridge => 78992,
    #         :dialNumber => "1-800-000-0000x00000#",
    #         :attendeePW => "12345",
    #         :moderatorPW => "54321",
    #         :hasBeenForciblyEnded => false,
    #         :running => true,
    #         :participantCount => 2,
    #         :listenerCount => 0,
    #         :videoCount => 0 }
    #     ],
    #     :messageKey => "",
    #     :message => ""
    #   }
    #
    # Server with no meetings:
    #
    #   {
    #     :returncode => true,
    #     :meetings => [],
    #     :messageKey => "noMeetings",
    #     :message => "no meetings were found on this server"
    #   }
    #
    def get_meetings(options={})
      response = send_api_request(:getMeetings, options)

      formatter = BigBlueButtonFormatter.new(response)
      formatter.flatten_objects(:meetings, :meeting)
      response[:meetings].each { |m| BigBlueButtonFormatter.format_meeting(m) }
      response
    end

    # Returns the API version of the server as a string. Will return the version in the response
    # given by the BigBlueButton server, and not the version set by the user in the initialization
    # of this object!
    def get_api_version
      response = send_api_request(:index)
      response[:returncode] ? response[:version].to_s : ""
    end


    #
    # API calls since 0.8
    #

    # Retrieves the recordings that are available for playback for a given meetingID (or set of meeting IDs).
    # options (Hash)::       Hash with additional parameters. The accepted parameters are:
    #                        :meetingID (string, Array). For details about each see BigBlueButton's
    #                        API docs.
    #                        Any of the following values are accepted for :meetingID :
    #                          :meetingID => "id1"
    #                          :meetingID => "id1,id2,id3"
    #                          :meetingID => ["id1"]
    #                          :meetingID => ["id1", "id2", "id3"]
    #                        If you have a custom API with more parameters, you can simply pass them
    #                        in this hash and they will be added to the API call.
    #
    # === Example responses
    #
    #   { :returncode => true,
    #     :recordings => [
    #       {
    #         :recordID => "7f5745a08b24fa27551e7a065849dda3ce65dd32-1321618219268",
    #         :meetingID => "bd1811beecd20f24314819a52ec202bf446ab94b",
    #         :name => "Evening Class1",
    #         :published => true,
    #         :startTime => #<DateTime: 2011-11-18T12:10:23+00:00 (212188378223/86400,0/1,2299161)>,
    #         :endTime => #<DateTime: 2011-11-18T12:12:25+00:00 (42437675669/17280,0/1,2299161)>,
    #         :metadata => { :course => "Fundamentals of JAVA",
    #                        :description => "List of recordings",
    #                        :activity => "Evening Class1" },
    #         :playback => {
    #           :format => [
    #             { :type => "slides",
    #               :url => "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
    #               :length => 64
    #             },
    #             { :type => "presentation",
    #               :url => "http://test-install.blindsidenetworks.com/presentation/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
    #               :length => 64
    #             }
    #           ]
    #         }
    #       },
    #       { :recordID => "1254kakap98sd09jk2lk2-1329872486234",
    #         :recordID => "7f5745a08b24fa27551e7a065849dda3ce65dd32-1321618219268",
    #         :meetingID => "bklajsdoiajs9d8jo23id90",
    #         :name => "Evening Class2",
    #         :published => false,
    #         :startTime => #<DateTime: 2011-11-18T12:10:23+00:00 (212188378223/86400,0/1,2299161)>,
    #         :endTime => #<DateTime: 2011-11-18T12:12:25+00:00 (42437675669/17280,0/1,2299161)>,
    #         :metadata => {},
    #         :playback => {
    #           :format => { # notice that this is now a hash, not an array
    #             :type => "slides",
    #             :url => "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=1254kakap98sd09jk2lk2-1329872486234",
    #             :length => 64
    #           }
    #         }
    #       }
    #     ]
    #   }
    #
    def get_recordings(options={})
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

    # Available since BBB v1.1
    # Update metadata (or other attributes depending on the API implementation) for a given recordID (or set of record IDs).
    # recordIDs (string, Array)::  ID or IDs of the target recordings.
    #                              Any of the following values are accepted:
    #                                "id1"
    #                                "id1,id2,id3"
    #                                ["id1"]
    #                                ["id1", "id2", "id3"]
    # meta (String)::         Pass one or more metadata values to be update (format is the same as in create call)
    # options (Hash)::        Hash with additional parameters. This method doesn't accept additional
    #                         parameters, but if you have a custom API with more parameters, you
    #                         can simply pass them in this hash and they will be added to the API call.
    #
    # === Example responses
    #
    #   { :returncode => success, :updated => true }      
    #
    def update_recordings(recordIDs, meta=nil, options={})
       recordIDs = recordIDs.join(",") if recordIDs.instance_of?(Array) # ["id1", "id2"] becomes "id1,id2"
       params = { :recordID => recordIDs, :meta => meta }.merge(options)
       send_api_request(:updateRecordings, params)
    end


    # Publish and unpublish recordings for a given recordID (or set of record IDs).
    # recordIDs (string, Array)::  ID or IDs of the target recordings.
    #                              Any of the following values are accepted:
    #                                "id1"
    #                                "id1,id2,id3"
    #                                ["id1"]
    #                                ["id1", "id2", "id3"]
    # publish (boolean)::     Whether to publish or unpublish the recording(s)
    # options (Hash)::        Hash with additional parameters. This method doesn't accept additional
    #                         parameters, but if you have a custom API with more parameters, you
    #                         can simply pass them in this hash and they will be added to the API call.
    #
    # === Example responses
    #
    #   { :returncode => true, :published => true }
    #
    def publish_recordings(recordIDs, publish, options={})
      recordIDs = recordIDs.join(",") if recordIDs.instance_of?(Array) # ["id1", "id2"] becomes "id1,id2"
      params = { :recordID => recordIDs, :publish => publish.to_s }.merge(options)
      send_api_request(:publishRecordings, params)
    end

    # Delete one or more recordings for a given recordID (or set of record IDs).
    # recordIDs (string, Array)::  ID or IDs of the target recordings.
    #                              Any of the following values are accepted:
    #                                "id1"
    #                                "id1,id2,id3"
    #                                ["id1"]
    #                                ["id1", "id2", "id3"]
    # options (Hash)::        Hash with additional parameters. This method doesn't accept additional
    #                         parameters, but if you have a custom API with more parameters, you
    #                         can simply pass them in this hash and they will be added to the API call.
    #
    # === Example responses
    #
    #   { :returncode => true, :deleted => true }
    #
    def delete_recordings(recordIDs, options={})
      recordIDs = recordIDs.join(",") if recordIDs.instance_of?(Array) # ["id1", "id2"] becomes "id1,id2"
      params = { :recordID => recordIDs }.merge(options)
      send_api_request(:deleteRecordings, params)
    end


    #
    # API calls since 0.81
    #

    # Retrieves the default config.xml file from the server.
    # Returns the XML as a string by default, but if `asObject` is set to true, returns the XML
    # parsed as an XmlSimple object ().
    # asObject (Hash)::       If true, returns the XML parsed as an XmlSimple object, using:
    #                           data = XmlSimple.xml_in(response, { 'ForceArray' => false, 'KeepRoot' => true })
    #                         You can then parse it back into an XML string using:
    #                           XmlSimple.xml_out(data, { 'RootName' => nil, 'XmlDeclaration' => true })
    #                         If set to false, returns the XML as a string.
    # options (Hash)::        Hash with additional parameters. This method doesn't accept additional
    #                         parameters, but if you have a custom API with more parameters, you
    #                         can simply pass them in this hash and they will be added to the API call.
    def get_default_config_xml(asObject=false, options={})
      response = send_api_request(:getDefaultConfigXML, options, nil, true)
      if asObject
        XmlSimple.xml_in(response, { 'ForceArray' => false, 'KeepRoot' => true })
      else
        response
      end
    end

    # Sets a config.xml file in the server.
    # Returns the token returned by the server (that can be later used in a 'join' call) in case
    # of success.
    # meeting_id (string)::                   The ID of the meeting where this config.xml will be used.
    # xml (string|BigBlueButtonConfigXml)::   The XML that should be sent as a config.xml.
    #                                         It will usually be an edited output of the default config.xml:
    #                                           xml = api.get_default_config_xml
    #                                         Or you can use directly a BigBlueButtonConfigXml object:
    #                                           BigBlueButtonConfigXml.new(xml)
    # options (Hash)::                        Hash with additional parameters. This method doesn't accept additional
    #                                         parameters, but if you have a custom API with more parameters, you
    #                                         can simply pass them in this hash and they will be added to the API call.
    # TODO: Right now we are sending the configXML parameters in the URL and in the body of the POST
    #   request. It works if left only in the URL, but the documentation of the API claims that it has
    #   to be in the body of the request. So it's no clear yet and this might change in the future.
    def set_config_xml(meeting_id, xml, options={})
      if xml.instance_of?(BigBlueButton::BigBlueButtonConfigXml)
        data = xml.as_string
      else
        data = xml
      end
      params = { :meetingID => meeting_id, :configXML => data }.merge(options)
      response = send_api_request(:setConfigXML, params, data)
      response[:configToken]
    end


    #
    # Helper functions
    #

    # Returns an array with the name of all layouts available in the server.
    # Will fetch the config.xml file (unless passed in the arguments), fetch the
    # layout definition file, and return the layouts.
    # If something goes wrong, returns nil. Otherwise returns the list of layout
    # names or an empty array if there's no layout defined.
    def get_available_layouts(config_xml=nil)
      config_xml = get_default_config_xml if config_xml.nil?
      config_xml = BigBlueButton::BigBlueButtonConfigXml.new(config_xml)
      layout_config = config_xml.get_attribute("LayoutModule", "layoutConfig", true)
      unless layout_config.nil?
        response = send_request(layout_config)
        layout_config = BigBlueButton::BigBlueButtonConfigLayout.new(response.body)
        layout_config.get_available_layouts
      else
        nil
      end
    end

    # Returns an array with the layouts that exist by default in a BigBlueButton
    # server. If you want to query the server to get a real list of layouts, use
    # <tt>get_available_layouts</tt>.
    def get_default_layouts
      # this is the list for BigBlueButton 0.81
      ["Default", "Video Chat", "Meeting", "Webinar", "Lecture assistant", "Lecture"]
    end

    # Make a simple request to the server to test the connection.
    def test_connection
      response = send_api_request(:index)
      response[:returncode]
    end

    def check_url
      url, data = get_url(:check)
      url
    end

    # API's are equal if all the following attributes are equal.
    def ==(other)
      r = true
      [:url, :supported_versions, :secret, :version, :debug].each do |param|
        r = r && self.send(param) == other.send(param)
      end
      r
    end

    # Returns the HTTP response object returned in the last API call.
    def last_http_response
      @http_response
    end

    # Returns the XML returned in the last API call.
    def last_xml_response
      @xml_response
    end

    # Formats an API call URL for the method 'method' using the parameters in 'params'.
    # method (symbol)::  The API method to be called (:create, :index, :join, and others)
    # params (Hash)::    The parameters to be passed in the URL
    def get_url(method, params={})
      if method == :index
        return @url, nil
      elsif method == :check
        baseurl = URI.join(@url, "/").to_s
        return "#{baseurl}check", nil
      end

      # stringify and escape all params
      params.delete_if { |k, v| v.nil? } unless params.nil?
      # some API calls require the params to be sorted
      # first make all keys symbols, so the comparison works
      params = params.inject({}){ |memo,(k,v)| memo[k.to_sym] = v; memo }
      params = Hash[params.sort]
      params_string = ""
      params_string = params.map{ |k,v| "#{k}=" + URI.encode_www_form_component(v.to_s) unless k.nil? || v.nil? }.join("&")

      # checksum calc
      checksum_param = params_string + @secret
      checksum_param = method.to_s + checksum_param
      checksum = Digest::SHA1.hexdigest(checksum_param)

      if method == :setConfigXML
        params_string = "checksum=#{checksum}&#{params_string}"
        return "#{@url}/#{method}", params_string
      else
        url = "#{@url}/#{method}?"
        url += "#{params_string}&" unless params_string.empty?
        url += "checksum=#{checksum}"
        return url, nil
      end
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
    # raw (boolean)::    If true, returns the data as it was received. Will not parse it into a Hash,
    #                    check for errors or throw exceptions.
    def send_api_request(method, params={}, data=nil, raw=false)
      # if the method returns a body, use it as the data in the post request
      url, body = get_url(method, params)
      data = body if body

      @http_response = send_request(url, data)
      return {} if @http_response.body.empty?
      @xml_response = @http_response.body

      if raw
        result = @xml_response
      else

        # 'Hashify' the XML
        result = BigBlueButtonHash.from_xml(@xml_response)

        # simple validation of the xml body
        unless result.has_key?(:returncode)
          raise BigBlueButtonException.new("Invalid response body. Is the API URL correct? \"#{@url}\", version #{@version}")
        end

        # default cleanup in the response
        result = BigBlueButtonFormatter.new(result).default_formatting

        # if the return code is an error generates an exception
        unless result[:returncode]
          exception = BigBlueButtonException.new(result[:message])
          exception.key = result.has_key?(:messageKey) ? result[:messageKey] : ""
          raise exception
        end
      end

      result
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
        http.use_ssl = true if url_parsed.scheme.downcase == 'https'

        if data.nil?
          response = http.get(url_parsed.request_uri, @request_headers)
        else
          puts "BigBlueButtonAPI: Sending as a POST request with data.size = #{data.size}" if @debug
          opts = { 'Content-Type' => 'application/x-www-form-urlencoded' }.merge @request_headers
          response = http.post(url_parsed.request_uri, data, opts)
        end
        puts "BigBlueButtonAPI: URL response = #{response.body}" if @debug

      rescue TimeoutError => error
        raise BigBlueButtonException.new("Timeout error. Your server is probably down: \"#{@url}\". Error: #{error}")

      rescue Exception => error
        raise BigBlueButtonException.new("Connection error. Your URL is probably incorrect: \"#{@url}\". Error: #{error}")
      end

      response
    end

    def nearest_version(target)
      version = target

      # 0.81 in BBB is actually < than 0.9, but not when comparing here
      # so normalize x.xx versions to x.x.x
      match = version.match(/(\d)\.(\d)(\d)/)
      version = "#{match[1]}.#{match[2]}.#{match[3]}" if match

      # we don't allow older versions than the one supported, use an old version of the gem for that
      if Gem::Version.new(version) < Gem::Version.new(@supported_versions[0])
        raise BigBlueButtonException.new("BigBlueButton error: Invalid API version #{version}. Supported versions: #{@supported_versions.join(', ')}")

      # allow newer versions by using the newest one we support
      elsif Gem::Version.new(version) > Gem::Version.new(@supported_versions.last)
        @supported_versions.last

      else
        target
      end
    end

  end
end
