require 'net/http'
require 'cgi'
require 'rexml/document'
require 'digest/sha1'
require 'rubygems'
require 'nokogiri'
require 'hash_to_xml'

module BigBlueButton

  class BigBlueButtonException < Exception
    attr_accessor :key

    def to_s
      unless key.blank?
        super.to_s + ", messageKey: #{key}"
      else
        super
      end
    end

  end

  # This class provides access to the BigBlueButton API. BigBlueButton
  # is an open source project that provides web conferencing for distance
  # education (http://code.google.com/p/bigbluebutton/wiki/API). This API
  # was developed to support the following version of BBB: 0.64, 0.7
  #
  # Sample usage of the API is as follows:
  # 1) Create a meeting with the create_meeting call
  # 2) Direct a user to either join_meeting_url
  # 3) To force meeting to end, call end_meeting
  #
  # 0.0.4+:
  # Author::    Leonardo Crauss Daronco  (mailto:leonardodaronco@gmail.com)
  # Copyright:: Copyright (c) 2011 Leonardo Crauss Daronco
  # Project::   GT-Mconf: Multiconference system for interoperable web and mobile @ PRAV Labs - UFRGS
  # License::   Distributes under same terms as Ruby
  #
  # 0.0.3 and below:
  # Author::    Joe Kinsella  (mailto:joe.kinsella@gmail.com)
  # Copyright:: Copyright (c) 2010 Joe Kinsella
  # License::   Distributes under same terms as Ruby
  #
  # TODO: Automatically detect API version using request to index - added in 0.7
  #
  # Considerations about the returning hash:
  # * The XML returned by BBB is converted to a Hash. See the desired method's documentation for examples.
  # * Three values will *always* exist in the hash: :returncode (boolean), :messageKey (string) and :message (string)
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

    attr_accessor :url, :supported_versions, :salt, :version, :debug

    # Initializes an instance
    # url::       URL to a BigBlueButton server (e.g. http://demo.bigbluebutton.org/bigbluebutton/api)
    # salt::      Secret salt for this server
    # version::   API version: 0.64 or 0.7
    def initialize(url, salt, version='0.7', debug=false)
      @supported_versions = ['0.7', '0.64']
      unless @supported_versions.include?(version)
        raise BigBlueButtonException.new("BigBlueButton error: Invalid API version #{version}. Supported versions: #{@supported_versions.join(', ')}")
      end
      @url = url
      @salt = salt
      @debug = debug
      @version = version
      puts "BigBlueButtonAPI: Using version #{@version}" if @debug
    end

    # DEPRECATED
    # Use join_meeting_url
    def moderator_url(meeting_id, user_name, password,
                      user_id = nil, web_voice_conf = nil)
      warn "#{caller[0]}: moderator_url is deprecated and will soon be removed, please use join_meeting_url instead."
      join_meeting_url(meeting_id, user_name, password, user_id, web_voice_conf)
    end

    # DEPRECATED
    # Use join_meeting_url
    def attendee_url(meeting_id, user_name, password,
                     user_id = nil, web_voice_conf = nil)
      warn "#{caller[0]}: attendee_url is deprecated and will soon be removed, please use join_meeting_url instead."
      join_meeting_url(meeting_id, user_name, password, user_id, web_voice_conf)
    end

    # Returns the url used to join the meeting
    # meeting_id::        Unique identifier for the meeting
    # user_name::         Name of the user
    # password::          Password for this meeting - used to set the user as moderator or attendee
    # user_id::           Unique identifier for this user (>= 0.7)
    # web_voice_conf::    Custom voice-extension for users using VoIP (>= 0.7)
    def join_meeting_url(meeting_id, user_name, password,
                         user_id = nil, web_voice_conf = nil)

      params = { :meetingID => meeting_id, :password => password, :fullName => user_name }
      if @version == '0.7'
        params[:userID] = user_id
        params[:webVoiceConf] = web_voice_conf
      end
      get_url(:join, params)
    end

    # Creates a new meeting. Returns the hash with the response or
    # throws BigBlueButtonException on failure.
    # meeting_name::        Name for the meeting
    # meeting_id::          Unique identifier for the meeting
    # moderator_password::  Moderator password
    # attendee_password::   Attendee password
    # welcome_message::     Welcome message to display in chat window
    # dialin_number::       Dial in number for conference using a regular phone
    # logout_url::          URL to return user to after exiting meeting
    # voice_bridge::        Voice conference number (>= 0.7)
    #
    # === Return examples (for 0.7)
    #
    # On successful creation:
    #
    #   {
    #    :returncode=>true, :meetingID=>"bigbluebutton-api-ruby-test",
    #    :attendeePW=>"1234", :moderatorPW=>"4321", :hasBeenForciblyEnded=>false,
    #    :messageKey=>"", :message=>""
    #   }
    #
    # Meeting that was forcibly ended:
    #
    #   {
    #    :returncode=>true, :meetingID=>"bigbluebutton-api-ruby-test",
    #    :attendeePW=>"1234", :moderatorPW=>"4321", :hasBeenForciblyEnded=>true,
    #    :messageKey=>"duplicateWarning",
    #    :message=>"This conference was already in existence and may currently be in progress."
    #   }
    #
    # TODO check if voice_bridge exists in 0.64
    def create_meeting(meeting_name, meeting_id, moderator_password, attendee_password,
                       welcome_message = nil, dial_number = nil, logout_url = nil,
                       max_participants = nil, voice_bridge = nil)

      params = { :name => meeting_name, :meetingID => meeting_id,
                 :moderatorPW => moderator_password, :attendeePW => attendee_password,
                 :welcome => welcome_message, :dialNumber => dial_number,
                 :logoutURL => logout_url, :maxParticpants => max_participants }
      params[:voiceBridge] = voice_bridge if @version == '0.7'

      response = send_api_request(:create, params)

      response[:meetingID] = response[:meetingID].to_s
      response[:moderatorPW] = response[:moderatorPW].to_s
      response[:attendeePW] = response[:attendeePW].to_s
      response[:hasBeenForciblyEnded] = response[:hasBeenForciblyEnded].downcase == "true"

      response
    end

    # Ends an existing meeting. Throws BigBlueButtonException on failure.
    # meeting_id::          Unique identifier for the meeting
    # moderator_password::  Moderator password
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
    # meeting_id::          Unique identifier for the meeting
    def is_meeting_running?(meeting_id)
      hash = send_api_request(:isMeetingRunning, { :meetingID => meeting_id } )
      hash[:running].downcase == "true"
    end

    # Warning: As of this version of the gem, this call does not work
    # (instead of returning XML response, it should join the meeting).
    #
    # Joins a user into the meeting using an API call, instead of
    # directing the user's browser to moderator_url or attendee_url
    # (note: this will still be required however to actually use bbb).
    # Returns the URL a user can use to enter this meeting.
    # meeting_id::        Unique identifier for the meeting
    # user_name::         Name of the user
    # password::          Moderator or attendee password for this meeting
    # user_id::           Unique identifier for this user (>=0.7)
    # web_voice_conf::    Custom voice-extension for users using VoIP (>=0.7)
    def join_meeting(meeting_id, user_name, password, user_id = nil, web_voice_conf = nil)
      params = { :meetingID => meeting_id, :password => password, :fullName => user_name }
      if @version == '0.64'
        params[:redirectImmediately] = 0
      elsif @version == '0.7'
        params[:userID] = user_id
        params[:webVoiceConf] = web_voice_conf
      end
      send_api_request(:join, params)
    end

    # Returns a hash object containing the meeting information.
    # See the API documentation for details on the return XML
    # (http://code.google.com/p/bigbluebutton/wiki/API).
    #
    # meeting_id::  Unique identifier for the meeting
    # password::    Moderator password for this meeting
    #
    # === Return examples (for 0.7)
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
    def get_meeting_info(meeting_id, password)
      response = send_api_request(:getMeetingInfo, { :meetingID => meeting_id, :password => password } )

      # simplify the hash making a node :attendees with an array with all attendees
      if response[:attendees].empty?
        attendees = []
      else
        node = response[:attendees][:attendee]
        if node.kind_of?(Array)
          attendees = node
        else
          attendees = []
          attendees << node
        end
      end
      response[:attendees] = attendees
      response[:attendees].each { |att| att[:role] = att[:role].downcase.to_sym }

      response[:meetingID] = response[:meetingID].to_s
      response[:moderatorPW] = response[:moderatorPW].to_s
      response[:attendeePW] = response[:attendeePW].to_s
      response[:hasBeenForciblyEnded] = response[:hasBeenForciblyEnded].downcase == "true"
      response[:running] = response[:running].downcase == "true"
      response[:startTime] = response[:startTime].downcase == "null" ?
                             nil : DateTime.parse(response[:startTime])
      response[:endTime] = response[:endTime].downcase == "null" ?
                           nil : DateTime.parse(response[:endTime])

      response
    end

    # Returns a hash object containing information about the meetings currently existent in the BBB
    # server, either they are running or not.
    #
    # === Return examples (for 0.7)
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

      # simplify the hash making a node :meetings with an array with all meetings
      if response[:meetings].empty?
        meetings = []
      else
        node = response[:meetings][:meeting]
        if node.kind_of?(Array)
          meetings = node
        else
          meetings = []
          meetings << node
        end
      end
      response[:meetings] = meetings

      response[:meetings].each do |meeting|
        meeting[:meetingID] = meeting[:meetingID].to_s
        meeting[:moderatorPW] = meeting[:moderatorPW].to_s
        meeting[:attendeePW] = meeting[:attendeePW].to_s
        meeting[:hasBeenForciblyEnded] = meeting[:hasBeenForciblyEnded].downcase == "true"
        meeting[:running] = meeting[:running].downcase == "true"
      end

      response
    end

    # Returns the API version (as string) of the associated server. This actually returns
    # the version requested to the BBB server, and not the version set by the user in
    # the initialization.
    #
    # Works for BBB >= 0.7 only. For earlier versions, returns an empty string.
    def get_api_version
      response = send_api_request(:index)
      if response[:returncode]
        response[:version].to_s
      else
        ""
      end
    end

    # Make a simple request to the server to test the connection
    def test_connection
      if @version == '0.7'
        response = send_api_request(:index)
      else
        response = get_meetings
      end
      response[:returncode]
    end

    # API's are equal if all the following attributes are equal
    def ==(other)
      r = true
      [:url, :supported_versions, :salt, :version, :debug].each do |param|
        r = r && self.send(param) == other.send(param)
      end
      r
    end

    protected

    def get_url(method, data)
      if method == :index
        return @url
      end

      url = "#{@url}/#{method}?"

      data.delete_if { |k, v| v.nil? } unless data.nil?
      params = ""
      params = data.map{ |k,v| "#{k}=" + CGI::escape(v.to_s) unless k.nil? || v.nil? }.join("&")

      checksum_param = params + @salt
      checksum_param = method.to_s + checksum_param if @version == '0.7'
      checksum = Digest::SHA1.hexdigest(checksum_param)

      "#{url}#{params}&checksum=#{checksum}"
    end

    def send_api_request(method, data = {})
      url = get_url(method, data)
      begin
        res = Net::HTTP.get_response(URI.parse(url))
        puts "BigBlueButtonAPI: URL request = #{url}" if @debug
        puts "BigBlueButtonAPI: URL response = #{res.body}" if @debug
      rescue Exception => socketerror
        raise BigBlueButtonException.new("Connection error. Your URL is probably incorrect: \"#{@url}\"")
      end

      if res.body.empty?
        raise BigBlueButtonException.new("No response body")
      end

      # 'Hashify' the XML
      hash = Hash.from_xml res.body

      # simple validation of the xml body
      unless hash.has_key?(:response) and hash[:response].has_key?(:returncode)
        raise BigBlueButtonException.new("Invalid response body. Is the API URL correct? \"#{@url}\", version #{@version}")
      end

      # and remove the "response" node
      hash = Hash[hash[:response]].inject({}){|h,(k,v)| h[k] = v; h}

      # Adjust some values. There will always be a returncode, message and messageKey in the hash.
      hash[:returncode] = hash[:returncode].downcase == "success"                                  # true instead of "SUCCESS"
      hash[:messageKey] = "" if !hash.has_key?(:messageKey) or hash[:messageKey].empty?            # "" instead of {}
      hash[:message] = "" if !hash.has_key?(:message) or hash[:message].empty?                     # "" instead of {}

      unless hash[:returncode]
        exception = BigBlueButtonException.new(hash[:message])
        exception.key = hash.has_key?(:messageKey) ? hash[:messageKey] : ""
        raise exception
      end

      hash
    end

  end
end


