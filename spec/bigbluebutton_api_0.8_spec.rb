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

    context "without modules" do
      let(:req_params) {
        { :name => "name", :meetingID => "meeting-id", :moderatorPW => "mp", :attendeePW => "ap",
          :welcome => "Welcome!", :dialNumber => 12345678, :logoutURL => "http://example.com",
          :maxParticipants => 25, :voiceBridge => 12345, :record => "true", :duration => 20,
          :meta_1 => "meta1", :meta_2 => "meta2" }
      }
      let(:req_response) {
        { :meetingID => 123, :moderatorPW => 111, :attendeePW => 222, :hasBeenForciblyEnded => "FALSE", :createTime => "123123123" }
      }
      let(:final_response) {
        { :meetingID => "123", :moderatorPW => "111", :attendeePW => "222", :hasBeenForciblyEnded => false, :createTime => 123123123 }
      }

      before { api.should_receive(:send_api_request).with(:create, req_params).and_return(req_response) }
      subject {
        options = { :moderatorPW => "mp", :attendeePW => "ap", :welcome => "Welcome!", :dialNumber => 12345678,
          :logoutURL => "http://example.com", :maxParticipants => 25, :voiceBridge => 12345, :record => true,
          :duration => 20, :meta_1 => "meta1", :meta_2 => "meta2" }
        api.create_meeting("name", "meeting-id", options)
      }
      it { subject.should == final_response }
    end

    context "with modules" do
      let(:req_params) {
        { :name => "name", :meetingID => "meeting-id", :moderatorPW => "mp", :attendeePW => "ap" }
      }
      let(:req_response) {
        { :meetingID => 123, :moderatorPW => 111, :attendeePW => 222, :hasBeenForciblyEnded => "FALSE", :createTime => "123123123" }
      }
      let(:final_response) {
        { :meetingID => "123", :moderatorPW => "111", :attendeePW => "222", :hasBeenForciblyEnded => false, :createTime => 123123123 }
      }
      let(:modules) {
        m = BigBlueButton::BigBlueButtonModules.new
        m.add_presentation(:url, "http://www.samplepdf.com/sample.pdf")
        m.add_presentation(:url, "http://www.samplepdf.com/sample2.pdf")
        m.add_presentation(:base64, "JVBERi0xLjQKJ....[clipped here]....0CiUlRU9GCg==", "first-class.pdf")
        m
      }

      before {
        api.should_receive(:send_api_request).with(:create, req_params, modules.to_xml).
          and_return(req_response)
      }
      subject {
        options = { :moderatorPW => "mp", :attendeePW => "ap" }
        api.create_meeting("name", "meeting-id", options, modules)
      }
      it { subject.should == final_response }
    end
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

  describe "#get_recordings" do
    let(:recording1) { { :recordID => "id1", :meetindID => "meeting-id" } } # simplified "recording" node in the response
    let(:recording2) { { :recordID => "id2", :meetindID => "meeting-id" } }
    let(:response) {
      { :returncode => true, :recordings => { :recording => [ recording1, recording2 ] }, :messageKey => "mkey", :message => "m" }
    }
    let(:flattened_response) {
      { :returncode => true, :recordings => [ recording1, recording2 ], :messageKey => "mkey", :message => "m" }
    } # hash *after* the flatten_objects call

    context "only supported for >= 0.8" do
      let(:api) { BigBlueButton::BigBlueButtonApi.new(url, salt, "0.7", debug) }
      it { expect { api.get_recordings }.to raise_error(BigBlueButton::BigBlueButtonException) }
    end

    context "accepts non standard options" do
      let(:params) { { :meetingID => "meeting-id", :nonStandard => 1 } }
      before { api.should_receive(:send_api_request).with(:getRecordings, params).and_return(response) }
      it { api.get_recordings(params) }
    end

    context "without meeting ID" do
      before { api.should_receive(:send_api_request).with(:getRecordings, {}).and_return(response) }
      it { api.get_recordings.should == response }
    end

    context "with one meeting ID" do
      context "in an array" do
        let(:options) { { :meetingID => ["meeting-id"] } }
        let(:req_params) { { :meetingID => "meeting-id" } }
        before { api.should_receive(:send_api_request).with(:getRecordings, req_params).and_return(response) }
        it { api.get_recordings(options).should == response }
      end

      context "in a string" do
        let(:options) { { :meetingID => "meeting-id" } }
        let(:req_params) { { :meetingID => "meeting-id" } }
        before { api.should_receive(:send_api_request).with(:getRecordings, req_params).and_return(response) }
        it { api.get_recordings(options).should == response }
      end
    end

    context "with several meeting IDs" do
      context "in an array" do
        let(:options) { { :meetingID => ["meeting-id-1", "meeting-id-2"] } }
        let(:req_params) { { :meetingID => "meeting-id-1,meeting-id-2" } }
        before { api.should_receive(:send_api_request).with(:getRecordings, req_params).and_return(response) }
        it { api.get_recordings(options).should == response }
      end

      context "in a string" do
        let(:options) { { :meetingID => "meeting-id-1,meeting-id-2" } }
        let(:req_params) { { :meetingID => "meeting-id-1,meeting-id-2" } }
        before { api.should_receive(:send_api_request).with(:getRecordings, req_params).and_return(response) }
        it { api.get_recordings(options).should == response }
      end
    end

    context "formats the response" do
      before {
        api.should_receive(:send_api_request).with(:getRecordings, anything).and_return(flattened_response)
        formatter_mock = mock(BigBlueButton::BigBlueButtonFormatter)
        formatter_mock.should_receive(:flatten_objects).with(:recordings, :recording)
        BigBlueButton::BigBlueButtonFormatter.should_receive(:format_recording).with(recording1)
        BigBlueButton::BigBlueButtonFormatter.should_receive(:format_recording).with(recording2)
        BigBlueButton::BigBlueButtonFormatter.should_receive(:new).and_return(formatter_mock)
      }
      it { api.get_recordings }
    end
  end

  describe "#publish_recordings" do
    context "only supported for >= 0.8" do
      let(:api) { BigBlueButton::BigBlueButtonApi.new(url, salt, "0.7", debug) }
      it { expect { api.publish_recordings("id", true) }.to raise_error(BigBlueButton::BigBlueButtonException) }
    end

    context "publish is converted to string" do
      let(:recordIDs) { "any" }
      let(:req_params) { { :publish => "false", :recordID => "any" } }
      before { api.should_receive(:send_api_request).with(:publishRecordings, req_params) }
      it { api.publish_recordings(recordIDs, false) }
    end

    context "with one recording ID" do
      context "in an array" do
        let(:recordIDs) { ["id-1"] }
        let(:req_params) { { :publish => "true", :recordID => "id-1" } }
        before { api.should_receive(:send_api_request).with(:publishRecordings, req_params) }
        it { api.publish_recordings(recordIDs, true) }
      end

      context "in a string" do
        let(:recordIDs) { "id-1" }
        let(:req_params) { { :publish => "true", :recordID => "id-1" } }
        before { api.should_receive(:send_api_request).with(:publishRecordings, req_params) }
        it { api.publish_recordings(recordIDs, true) }
      end
    end

    context "with several recording IDs" do
      context "in an array" do
        let(:recordIDs) { ["id-1", "id-2"] }
        let(:req_params) { { :publish => "true", :recordID => "id-1,id-2" } }
        before { api.should_receive(:send_api_request).with(:publishRecordings, req_params) }
        it { api.publish_recordings(recordIDs, true) }
      end

      context "in a string" do
        let(:recordIDs) { "id-1,id-2,id-3" }
        let(:req_params) { { :publish => "true", :recordID => "id-1,id-2,id-3" } }
        before { api.should_receive(:send_api_request).with(:publishRecordings, req_params) }
        it { api.publish_recordings(recordIDs, true) }
      end
    end
  end

  describe "#delete_recordings" do
    context "only supported for >= 0.8" do
      let(:api) { BigBlueButton::BigBlueButtonApi.new(url, salt, "0.7", debug) }
      it { expect { api.delete_recordings("id") }.to raise_error(BigBlueButton::BigBlueButtonException) }
    end

    context "with one recording ID" do
      context "in an array" do
        let(:recordIDs) { ["id-1"] }
        let(:req_params) { { :recordID => "id-1" } }
        before { api.should_receive(:send_api_request).with(:deleteRecordings, req_params) }
        it { api.delete_recordings(recordIDs) }
      end

      context "in a string" do
        let(:recordIDs) { "id-1" }
        let(:req_params) { { :recordID => "id-1" } }
        before { api.should_receive(:send_api_request).with(:deleteRecordings, req_params) }
        it { api.delete_recordings(recordIDs) }
      end
    end

    context "with several recording IDs" do
      context "in an array" do
        let(:recordIDs) { ["id-1", "id-2"] }
        let(:req_params) { { :recordID => "id-1,id-2" } }
        before { api.should_receive(:send_api_request).with(:deleteRecordings, req_params) }
        it { api.delete_recordings(recordIDs) }
      end

      context "in a string" do
        let(:recordIDs) { "id-1,id-2,id-3" }
        let(:req_params) { { :recordID => "id-1,id-2,id-3" } }
        before { api.should_receive(:send_api_request).with(:deleteRecordings, req_params) }
        it { api.delete_recordings(recordIDs) }
      end
    end
  end

  describe "#get_meeting_info" do
    let(:params) { { :meetingID => "meeting-id", :password => "password" } }

    # new values were added in the response in 0.8 (we'll only test these values):
    #   meetingName, participantCount, maxUsers, voiceBridge, recording, metadata
    let(:response) {
      { :meetingName => 123, :maxUsers => "100", :voiceBridge => "12341234",
        :createTime => "123123123", :attendees => { :attendee => [ ] },
        :messageKey => "mkey", :message => "m", :recording => "false", :meta_1 => "abc", :meta_2 => "2" }
    }

    before { api.should_receive(:send_api_request).with(:getMeetingInfo, params).and_return(response) }
    subject { api.get_meeting_info("meeting-id", "password") }
    it { subject[:meetingName].should == "123" }
    it { subject[:maxUsers].should == 100 }
    it { subject[:voiceBridge].should == 12341234 }
    it { subject[:createTime].should == 123123123 }
    it { subject[:recording].should == false }
    it { subject[:meta_1].should == "abc" }
    it { subject[:meta_2].should == "2" }
  end

end
