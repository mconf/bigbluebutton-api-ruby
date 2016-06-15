require 'spec_helper'

# Tests for BBB API version 0.81
describe BigBlueButton::BigBlueButtonApi do

  # default variables and API object for all tests
  let(:url) { "http://server.com" }
  let(:secret) { "1234567890abcdefghijkl" }
  let(:version) { "0.9" }
  let(:debug) { false }
  let(:api) { BigBlueButton::BigBlueButtonApi.new(url, secret, version, debug) }

  describe "#create_meeting" do
    context "accepts the new parameters" do
      let(:req_params) {
        { :name => "name", :meetingID => "meeting-id",
          :moderatorOnlyMessage => "my-msg", :autoStartRecording => "false",
          :allowStartStopRecording => "true"
        }
      }

      before { api.should_receive(:send_api_request).with(:create, req_params) }
      it {
        options = {
          :moderatorOnlyMessage => "my-msg",
          :autoStartRecording => "false",
          :allowStartStopRecording => "true"
        }
        api.create_meeting("name", "meeting-id", options)
      }
    end
  end
end
