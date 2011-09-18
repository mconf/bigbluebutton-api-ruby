require 'spec_helper'

# Tests for BBB API version 0.8
describe BigBlueButton::BigBlueButtonApi do

  # default variables and API object for all tests
  let(:url) { "http://server.com" }
  let(:salt) { "1234567890abcdefghijkl" }
  let(:version) { "0.8" }
  let(:debug) { false }
  let(:api) { BigBlueButton::BigBlueButtonApi.new(url, salt, version, debug) }

  describe "#create_meeting" do
    let(:send_api_request_params) {
      { :name => "name", :meetingID => "meeting-id", :moderatorPW => "mp", :attendeePW => "ap",
        :welcome => "Welcome!", :dialNumber => 12345678, :logoutURL => "http://example.com",
        :maxParticipants => 25, :voiceBridge => 12345, :record => "true", :duration => 20,
        :meta_1 => "meta1", :meta_2 => "meta2" }
    }
    let(:send_api_request_response) {
      { :meetingID => 123, :moderatorPW => 111, :attendeePW => 222, :hasBeenForciblyEnded => "FALSE" }
    }
    let(:expected_response) {
      { :meetingID => "123", :moderatorPW => "111", :attendeePW => "222", :hasBeenForciblyEnded => false }
    }

    before { api.should_receive(:send_api_request).with(:create, send_api_request_params).and_return(send_api_request_response) }
    subject {
      options = { :moderatorPW => "mp", :attendeePW => "ap", :welcome => "Welcome!", :dialNumber => 12345678,
        :logoutURL => "http://example.com", :maxParticipants => 25, :voiceBridge => 12345, :record => true,
        :duration => 20, :meta_1 => "meta1", :meta_2 => "meta2" }
      api.create_meeting("name", "meeting-id", options)
    }
    it { subject.should == expected_response }
  end

  describe "#join_meeting_url" do
    let(:params) {
      { :meetingID => "meeting-id", :password => "pw", :fullName => "Name",
        :userID => "id123", :webVoiceConf => 12345678, :createTime => 9876543 }
    }

    before { api.should_receive(:get_url).with(:join, params).and_return("test-url") }
    it {
      options = { :userID => "id123", :webVoiceConf => 12345678, :createTime => 9876543 }
      api.join_meeting_url("meeting-id", "Name", "pw", options).should == "test-url"
    }
  end

  describe "#join_meeting" do
    let(:params) {
      { :meetingID => "meeting-id", :password => "pw", :fullName => "Name",
        :userID => "id123", :webVoiceConf => 12345678, :createTime => 9876543 }
    }

    before { api.should_receive(:send_api_request).with(:join, params).and_return("join-return") }
    it {
      options = { :userID => "id123", :webVoiceConf => 12345678, :createTime => 9876543 }
      api.join_meeting("meeting-id", "Name", "pw", options).should == "join-return"
    }
  end

end
