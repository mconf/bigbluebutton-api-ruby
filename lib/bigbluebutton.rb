require 'net/http'
require 'cgi'
require 'rexml/document'
require 'digest/sha1'

module BigBlueButton

  class BigBlueButtonException < Exception

  end

  # This class provides access to the BigBlueButton API.  BigBlueButton
  # is an open source project that provides web conferencing for distance
  # education (http://code.google.com/p/bigbluebutton/wiki/API).  This API
  # was developed to the 0.64 version of bbb.
  # 
  # Sample usage of the API is as follows:
  # 1) Create a meeting with the create_meeting call
  # 2) Direct a user to either moderator_url or attendee_url
  # 3) To force meeting to end, call end_meeting
  #
  # Author::    Joe Kinsella  (mailto:joe.kinsella@gmail.com)
  # Copyright:: Copyright (c) 2010 Joe Kinsella
  # License::   Distributes under same terms as Ruby
  class BigBlueButtonApi

    # Initializes an instance
    # base_url::  URL to a BigBlueButton server (defaults to bbb development server)
    # salt::      Secret salt for this server (defaults to bbb development server)"http://devbuild.bigbluebu
    def initialize(base_url, salt, debug=false)
      @session = {}
      @base_url = base_url
      @salt = salt
      @debug = debug
    end

    # Returns url to login as moderator
    # meeting_id::  Unique identifier for the meeting
    # user_name::   Name of the user
    # password::    Moderator password for this meeting
    def moderator_url(meeting_id, user_name, password)
      attendee_url(meeting_id, user_name, password)
    end

    # Returns url to login as attendee
    # meeting_id::  Unique identifier for the meeting
    # user_name::   Name of the user
    # password::    Attendee password for this meeting
    def attendee_url(meeting_id, user_name, attendee_password)
      get_url(:join, {:meetingID=>meeting_id,:password=>attendee_password, :fullName=>user_name})
    end

    # Creates a new meeting.  Returns the meeting token or
    # throws BigBlueButtonException on failure.
    # meeting_id::          Unique identifier for the meeting
    # meeting_name::        Name for the meeting
    # moderator_password::  Moderator password
    # attendee_password::   Attendee password
    # welcome_message::     Welcome message to display in chat window
    # dialin_number::       Dial in number for conference
    # logout_url::          URL to return user to after exiting meeting
    def create_meeting(meeting_id, meeting_name, moderator_password, attendee_password, 
        welcome_message = nil, dialin_number = nil, logout_url = nil, max_participants = nil)

      doc = send_api_request(:create, {:name=>meeting_name, :meetingID=>meeting_id,
          :moderatorPW=>moderator_password, :attendeePW=>attendee_password,
          :welcome=>welcome_message, :dialNumber=>dialin_number,
          :logoutURL=>logout_url, :maxParticpants=>max_participants} )
      doc.root.get_text('/response/meetingToken').to_s
    end

    # Ends an existing meeting.  Throws BigBlueButtonException on failure.
    # meeting_id::          Unique identifier for the meeting
    # moderator_password::  Moderator password
    def end_meeting(meeting_id, moderator_password)
      send_api_request(:end, {:meetingID=>meeting_id,:password=>moderator_password} )
    end

    # Returns true or false as to whether meeting is open.  A meeting is
    # only open after at least one participant has joined.
    # meeting_id::          Unique identifier for the meeting
    def is_meeting_running(meeting_id)
      doc = send_api_request(:isMeetingRunning, {:meetingID=>meeting_id} )
      running = doc.root.get_text('/response/running').to_s
      running == "true"
    end

    # Warning: As of this version of the gem, this bbb call does not work
    # (instead of returning XML response, joins meeting).
    #
    # Joins a user into the meeting using an API call, instead of
    # directing the user's browser to moderator_url or attendee_url
    # (note: this will still be required however to actually use bbb).
    # Returns the URL a user can use to enter this meeting.
    # meeting_id::  Unique identifier for the meeting
    # user_name::   Name of the user
    # password::    Moderator or attendee password for this meeting
    def join_meeting(meeting_id, user_name, password)
      send_api_request(:join, {:meetingID=>meeting_id, :password=>password,
          :fullName=>user_name, :redirectImmediately=>0} )
      doc.root.get_text('/response/entryURL').to_s
    end

    # Returns a REXML::Document object containing the meeting information.
    # See the API documentation for details on the return XML
    # (http://code.google.com/p/bigbluebutton/wiki/API).
    #
    # meeting_id::  Unique identifier for the meeting
    # password::    Moderator password for this meeting
    def get_meeting_info(meeting_id, password)
      send_api_request(:getMeetingInfo, {:meetingID=>meeting_id, :password=>password} )
    end

    protected

    def get_url(method, data)
      base_url = "#{@base_url}/#{method}?"
      params = ""
      data.each {|key, value|
        params += key.to_s + "=" + CGI.escape(value.to_s) + "&" unless key.nil? || value.nil?
      }
      checksum = Digest::SHA1.hexdigest(params.chop + @salt)
      "#{base_url}#{params}checksum=#{checksum}"
    end

    def send_api_request(method, data = {})
      url = get_url(method, data)
      res = Net::HTTP.get_response(URI.parse(url))
      puts "BigBlueButtonAPI: URL=#{url}" if @debug
      puts "BigBlueButtonAPI: URL response=#{res.body}" if @debug
      doc = REXML::Document.new(res.body)
      return_code = doc.root.get_text('/response/returncode')
      message = doc.root.get_text('/response/message')
      unless return_code == "SUCCESS"
        raise BigBlueButtonException.new("BigBlueButton error: #{message}")
      end
      doc
    end

  end

end