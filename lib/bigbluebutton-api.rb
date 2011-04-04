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
      join_meeting_url_url(meeting_id, user_name, password, user_id, web_voice_conf)
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
    # voice_bridge::        Voice conference number (>=0.7)
    # TODO check if voice_bridge exists in 0.64
    def create_meeting(meeting_name, meeting_id, moderator_password, attendee_password,
                       welcome_message = nil, dial_number = nil, logout_url = nil,
                       max_participants = nil, voice_bridge = nil)

      params = { :name => meeting_name, :meetingID => meeting_id,
                 :moderatorPW => moderator_password, :attendeePW => attendee_password,
                 :welcome => welcome_message, :dialNumber => dial_number,
                 :logoutURL => logout_url, :maxParticpants => max_participants }
      params[:voiceBridge] = voice_bridge if @version == '0.7'
      send_api_request(:create, params)
    end

    # Ends an existing meeting.  Throws BigBlueButtonException on failure.
    # meeting_id::          Unique identifier for the meeting
    # moderator_password::  Moderator password
    def end_meeting(meeting_id, moderator_password)
      send_api_request(:end, { :meetingID => meeting_id, :password => moderator_password } )
    end

    # Returns true or false as to whether meeting is open.  A meeting is
    # only open after at least one participant has joined.
    # meeting_id::          Unique identifier for the meeting
    def is_meeting_running?(meeting_id)
      hash = send_api_request(:isMeetingRunning, { :meetingID => meeting_id } )
      hash[:running] == "true"
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
    def get_meeting_info(meeting_id, password)
      send_api_request(:getMeetingInfo, { :meetingID => meeting_id, :password => password } )
    end

    # Returns a hash object containing the meeting information.
    # See the API documentation for details on the return XML
    # (http://code.google.com/p/bigbluebutton/wiki/API).
    def get_meetings
      send_api_request(:getMeetings, { :random => rand(9999999999) } )
    end

    # Make a simple request to the server to test the connection
    # TODO implement test for version 0.64
    def test_connection
      if @version == '0.7'
        response = send_api_request(:index)
        response[:returncode] == "SUCCESS"
      else
        true
      end
    end

    # API's are equal if all the following attributes are equal
    def == other
      r = true
      [:url, :supported_versions, :salt, :version, :debug].each do |param|
        r = r and self.send(param) == other.send(param)
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
      puts "BigBlueButtonAPI: URL response hash = #{hash.inspect}" if @debug

      return_code = hash[:returncode]
      unless return_code == "SUCCESS"
        exception = BigBlueButtonException.new(hash[:message])
        exception.key = hash.has_key?(:messageKey) ? hash[:messageKey] : ""
        raise exception
      end
      hash
    end

  end
end


