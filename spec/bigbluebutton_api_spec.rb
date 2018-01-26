require 'spec_helper'

# Note: Uses version 0.8 by default. For things that only exist in newer versions,
#   there are separate files with more tests.
describe BigBlueButton::BigBlueButtonApi do

  shared_examples_for "BigBlueButtonApi" do |version|

    # default variables and API object for all tests
    let(:url) { "http://server.com" }
    let(:secret) { "1234567890abcdefghijkl" }
    let(:debug) { false }
    let(:api) { BigBlueButton::BigBlueButtonApi.new(url, secret, version, debug) }

    describe "#initialize" do
      context "standard initialization" do
        subject { BigBlueButton::BigBlueButtonApi.new(url, secret, version, debug) }
        it { subject.url.should == url }
        it { subject.secret.should == secret }
        it { subject.version.should == version }
        it { subject.debug.should == debug }
        it { subject.timeout.should == 10 }
        it { subject.supported_versions.should include("0.8") }
        it { subject.supported_versions.should include("0.81") }
        it { subject.supported_versions.should include("0.9") }
        it { subject.request_headers.should == {} }
      end

      context "when the version is not informed, get it from the BBB server" do
        before { BigBlueButton::BigBlueButtonApi.any_instance.should_receive(:get_api_version).and_return("0.8") }
        subject { BigBlueButton::BigBlueButtonApi.new(url, secret, nil) }
        it { subject.version.should == "0.8" }
      end

      context "when the version informed is empty, get it from the BBB server" do
        before { BigBlueButton::BigBlueButtonApi.any_instance.should_receive(:get_api_version).and_return("0.8") }
        subject { BigBlueButton::BigBlueButtonApi.new(url, secret, "  ") }
        it { subject.version.should == "0.8" }
      end

      it "when the version is lower than the lowest supported, raise exception" do
        expect {
          BigBlueButton::BigBlueButtonApi.new(url, secret, "0.1", nil)
        }.to raise_error(BigBlueButton::BigBlueButtonException)
      end

      it "when the version is higher than thew highest supported, use the highest supported" do
        BigBlueButton::BigBlueButtonApi.new(url, secret, "5.0", nil).version.should eql('1.0')
      end

      it "compares versions in the format 'x.xx' properly" do
        expect {
          # if not comparing properly, 0.61 would be bigger than 0.9, for example
          # comparing the way BBB does, it is lower, so will raise an exception
          BigBlueButton::BigBlueButtonApi.new(url, secret, "0.61", nil)
        }.to raise_error(BigBlueButton::BigBlueButtonException)
      end

      context "current supported versions" do
        before {
          BigBlueButton::BigBlueButtonApi.any_instance.should_receive(:get_api_version).and_return("0.9")
        }
        subject { BigBlueButton::BigBlueButtonApi.new(url, secret) }
        it { subject.supported_versions.should == ["0.8", "0.81", "0.9", "1.0"] }
      end
    end

    describe "#create_meeting" do
      context "standard case" do
        let(:req_params) {
          { :name => "name", :meetingID => "meeting-id", :moderatorPW => "mp", :attendeePW => "ap",
            :welcome => "Welcome!", :dialNumber => 12345678, :logoutURL => "http://example.com",
            :maxParticipants => 25, :voiceBridge => 12345, :webVoice => "12345abc", :record => "true" }
        }
        let(:req_response) {
          { :meetingID => 123, :moderatorPW => 111, :attendeePW => 222, :hasBeenForciblyEnded => "FALSE" }
        }
        let(:final_response) {
          { :meetingID => "123", :moderatorPW => "111", :attendeePW => "222", :hasBeenForciblyEnded => false }
        }

        # ps: not mocking the formatter here because it's easier to just check the results (final_response)
        before { api.should_receive(:send_api_request).with(:create, req_params).and_return(req_response) }
        subject {
          options = { :moderatorPW => "mp", :attendeePW => "ap", :welcome => "Welcome!",
            :dialNumber => 12345678, :logoutURL => "http://example.com", :maxParticipants => 25,
            :voiceBridge => 12345, :webVoice => "12345abc", :record => "true" }
          api.create_meeting("name", "meeting-id", options)
        }
        it { subject.should == final_response }
      end

      context "accepts non standard options" do
        let(:params) {
          { :name => "name", :meetingID => "meeting-id",
            :moderatorPW => "mp", :attendeePW => "ap", :nonStandard => 1 }
        }
        before { api.should_receive(:send_api_request).with(:create, params) }
        it { api.create_meeting("name", "meeting-id", params) }
      end

      context "accepts :record as boolean" do
        let(:req_params) {
          { :name => "name", :meetingID => "meeting-id",
            :moderatorPW => "mp", :attendeePW => "ap", :record => "true" }
        }
        before { api.should_receive(:send_api_request).with(:create, req_params) }
        it {
          params = { :name => "name", :meetingID => "meeting-id",
            :moderatorPW => "mp", :attendeePW => "ap", :record => true }
          api.create_meeting("name", "meeting-id", params)
        }
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
    end

    describe "#end_meeting" do
      let(:meeting_id) { "meeting-id" }
      let(:moderator_password) { "password" }

      context "standard case" do
        let(:params) { { :meetingID => meeting_id, :password => moderator_password } }
        let(:response) { "anything" }

        before { api.should_receive(:send_api_request).with(:end, params).and_return(response) }
        it { api.end_meeting(meeting_id, moderator_password).should == response }
      end

      context "accepts non standard options" do
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        let(:params_out) {
          { :meetingID => meeting_id, :password => moderator_password,
            :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:end, params_out) }
        it { api.end_meeting(meeting_id, moderator_password, params_in) }
      end
    end

    describe "#is_meeting_running?" do
      let(:meeting_id) { "meeting-id" }
      let(:params) { { :meetingID => meeting_id } }

      context "when the meeting is running" do
        let(:response) { { :running => "TRUE" } }
        before { api.should_receive(:send_api_request).with(:isMeetingRunning, params).and_return(response) }
        it { api.is_meeting_running?(meeting_id).should == true }
      end

      context "when the meeting is not running" do
        let(:response) { { :running => "FALSE" } }
        before { api.should_receive(:send_api_request).with(:isMeetingRunning, params).and_return(response) }
        it { api.is_meeting_running?(meeting_id).should == false }
      end

      context "accepts non standard options" do
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        let(:params_out) {
          { :meetingID => meeting_id, :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:isMeetingRunning, params_out) }
        it { api.is_meeting_running?(meeting_id, params_in) }
      end
    end

    describe "#join_meeting_url" do
      context "standard case" do
        let(:params) {
          { :meetingID => "meeting-id", :password => "pw", :fullName => "Name",
            :userID => "id123", :webVoiceConf => 12345678, :createTime => 9876543 }
        }

        before { api.should_receive(:get_url).with(:join, params).and_return(["test-url", nil]) }
        it {
          options = { :userID => "id123", :webVoiceConf => 12345678, :createTime => 9876543 }
          api.join_meeting_url("meeting-id", "Name", "pw", options).should == "test-url"
        }
      end

      context "accepts non standard options" do
        let(:params) {
          { :meetingID => "meeting-id", :password => "pw",
            :fullName => "Name", :userID => "id123", :nonStandard => 1 }
        }
        before { api.should_receive(:get_url).with(:join, params) }
        it { api.join_meeting_url("meeting-id", "Name", "pw", params) }
      end
    end

    describe "#get_meeting_info" do
      let(:meeting_id) { "meeting-id" }
      let(:password) { "password" }

      context "standard case" do
        let(:params) { { :meetingID => meeting_id, :password => password } }

        let(:attendee1) { { :userID => 123, :fullName => "Dexter Morgan", :role => "MODERATOR" } }
        let(:attendee2) { { :userID => "id2", :fullName => "Cameron", :role => "VIEWER" } }
        let(:response) {
          { :meetingID => 123, :moderatorPW => 111, :attendeePW => 222, :hasBeenForciblyEnded => "FALSE",
            :running => "TRUE", :startTime => "Thu Sep 01 17:51:42 UTC 2011", :endTime => "null",
            :returncode => true, :attendees => { :attendee => [ attendee1, attendee2 ] },
            :messageKey => "mkey", :message => "m", :participantCount => "50", :moderatorCount => "3",
            :meetingName => "meeting-name", :maxUsers => "100", :voiceBridge => "12341234", :createTime => "123123123",
            :recording => "false", :meta_1 => "abc", :meta_2 => "2" }
        } # hash after the send_api_request call, before the formatting

        let(:expected_attendee1) { { :userID => "123", :fullName => "Dexter Morgan", :role => :moderator } }
        let(:expected_attendee2) { { :userID => "id2", :fullName => "Cameron", :role => :viewer } }
        let(:final_response) {
          { :meetingID => "123", :moderatorPW => "111", :attendeePW => "222", :hasBeenForciblyEnded => false,
            :running => true, :startTime => DateTime.parse("Thu Sep 01 17:51:42 UTC 2011"), :endTime => nil,
            :returncode => true, :attendees => [ expected_attendee1, expected_attendee2 ],
            :messageKey => "mkey", :message => "m", :participantCount => 50, :moderatorCount => 3,
            :meetingName => "meeting-name", :maxUsers => 100, :voiceBridge => 12341234, :createTime => 123123123,
            :recording => false, :meta_1 => "abc", :meta_2 => "2" }
        } # expected return hash after all the formatting

        # ps: not mocking the formatter here because it's easier to just check the results (final_response)
        before { api.should_receive(:send_api_request).with(:getMeetingInfo, params).and_return(response) }
        it { api.get_meeting_info(meeting_id, password).should == final_response }
      end

      context "accepts non standard options" do
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        let(:params_out) {
          { :meetingID => meeting_id, :password => password,
            :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:getMeetingInfo, params_out).and_return({}) }
        it { api.get_meeting_info(meeting_id, password, params_in) }
      end
    end

    describe "#get_meetings" do
      context "standard case" do
        let(:meeting_hash1) { { :meetingID => "Demo Meeting", :attendeePW => "ap", :moderatorPW => "mp", :hasBeenForciblyEnded => false, :running => true } }
        let(:meeting_hash2) { { :meetingID => "Ended Meeting", :attendeePW => "pass", :moderatorPW => "pass", :hasBeenForciblyEnded => true, :running => false } }
        let(:flattened_response) {
          { :returncode => true, :meetings => [ meeting_hash1, meeting_hash2 ], :messageKey => "mkey", :message => "m" }
        } # hash *after* the flatten_objects call

        before {
          api.should_receive(:send_api_request).with(:getMeetings, {}).
          and_return(flattened_response)
          formatter_mock = mock(BigBlueButton::BigBlueButtonFormatter)
          formatter_mock.should_receive(:flatten_objects).with(:meetings, :meeting)
          BigBlueButton::BigBlueButtonFormatter.should_receive(:new).and_return(formatter_mock)
          BigBlueButton::BigBlueButtonFormatter.should_receive(:format_meeting).with(meeting_hash1)
          BigBlueButton::BigBlueButtonFormatter.should_receive(:format_meeting).with(meeting_hash2)
        }
        it { api.get_meetings }
      end

      context "accepts non standard options" do
        let(:params) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:getMeetings, params).and_return({}) }
        it { api.get_meetings(params) }
      end
    end

    describe "#get_api_version" do
      context "returns the version returned by the server" do
        let(:hash) { { :returncode => true, :version => "0.8" } }
        before { api.should_receive(:send_api_request).with(:index).and_return(hash) }
        it { api.get_api_version.should == "0.8" }
      end

      context "returns an empty string when the server responds with an empty hash" do
        before { api.should_receive(:send_api_request).with(:index).and_return({}) }
        it { api.get_api_version.should == "" }
      end
    end

    describe "#test_connection" do
      context "returns the returncode returned by the server" do
        let(:hash) { { :returncode => "any-value" } }
        before { api.should_receive(:send_api_request).with(:index).and_return(hash) }
        it { api.test_connection.should == "any-value" }
      end
    end

    describe "#check_url" do
      context "when method = :check" do
        it {
          api.url = 'http://my-test-server.com/bigbluebutton/api'
          api.check_url.should == 'http://my-test-server.com/check'
        }
      end
    end

    describe "#==" do
      let(:api2) { BigBlueButton::BigBlueButtonApi.new(url, secret, version, debug) }

      context "compares attributes" do
        it { api.should == api2 }
      end

      context "differs #debug" do
        before { api2.debug = !api.debug }
        it { api.should_not == api2 }
      end

      context "differs #secret" do
        before { api2.secret = api.secret + "x" }
        it { api.should_not == api2 }
      end

      context "differs #version" do
        before { api2.version = api.version + "x" }
        it { api.should_not == api2 }
      end

      context "differs #supported_versions" do
        before { api2.supported_versions << "x" }
        it { api.should_not == api2 }
      end
    end

    describe "#last_http_response" do
      # we test this through a #test_connection call

      let(:request_mock) { mock }
      before {
        api.should_receive(:get_url)
        # this return value will be stored in @http_response
        api.should_receive(:send_request).and_return(request_mock)
        # to return fast from #send_api_request
        request_mock.should_receive(:body).and_return("")
        api.test_connection
      }
      it { api.last_http_response.should == request_mock }
    end

    describe "#last_xml_response" do
      # we test this through a #test_connection call

      let(:request_mock) { mock }
      let(:expected_xml) { "<response><returncode>SUCCESS</returncode></response>" }
      before {
        api.should_receive(:get_url)
        api.should_receive(:send_request).and_return(request_mock)
        request_mock.should_receive(:body).at_least(1).and_return(expected_xml)
        api.test_connection
      }
      it { api.last_xml_response.should == expected_xml }
    end

    describe "#get_url" do

      context "when method = :index" do
        it { api.get_url(:index).should == [api.url, nil] }
      end

      context "when method = :check" do
        it {
          api.url = 'http://my-test-server.com/bigbluebutton/api'
          api.get_url(:check).should == ['http://my-test-server.com/check', nil]
        }
      end

      context "when method != :index" do
        context "validates the entire url" do
          context "with params" do
            let(:params) { { :param1 => "value1", :param2 => "value2" } }
            subject { api.get_url(:join, params)[0] }
            it {
              # the hash can be sorted differently depending on the ruby version
              if params.map{ |k,v| "#{k}" }.join =~ /^param1/
                subject.should match(/#{url}\/join\?param1=value1&param2=value2/)
              else
                subject.should match(/#{url}\/join\?param2=value2&param1=value1/)
              end
            }
          end

          context "without params" do
            subject { api.get_url(:join)[0] }
            it { subject.should match(/#{url}\/join\?[^&]/) }
          end
        end

        context "when method = :setConfigXML" do
          it {
            api.url = 'http://my-test-server.com/bigbluebutton/api'
            response = api.get_url(:setConfigXML, { param1: 1, param2: 2 })
            response[0].should eql('http://my-test-server.com/bigbluebutton/api/setConfigXML')
            response[1].should match(/checksum=.*&param1=1&param2=2/)
          }
        end

        context "discards params with nil value" do
          let(:params) { { :param1 => "value1", :param2 => nil } }
          subject { api.get_url(:join, params)[0] }
          it { subject.should_not match(/param2=/) }
        end

        context "escapes all params" do
          let(:params) { { :param1 => "value with spaces", :param2 => "@$" } }
          subject { api.get_url(:join, params)[0] }
          it { subject.should match(/param1=value\+with\+spaces/) }
          it { subject.should match(/param2=%40%24/) }
        end

        [ [' ', '+'],
          ['*', '*']
        ].each do |values|
          context "escapes #{values[0].inspect} as #{values[1].inspect}" do
            let(:params) { { param1: "before#{values[0]}after" } }
            subject { api.get_url(:join, params)[0] }
            it { subject.should match(/param1=before#{Regexp.quote(values[1])}after/) }
          end
        end

        context "includes the checksum" do
          let(:params) { { :param1 => "value1", :param2 => "value2" } }
          let(:checksum) {
            # the hash can be sorted differently depending on the ruby version
            if params.map{ |k,v| k }.join =~ /^param1/
              "67882ae54f49600f56f358c10d24697ef7d8c6b2"
            else
              "85a54e28e4ec18bfdcb214a73f74d35b09a84176"
            end
          }
          subject { api.get_url(:join, params)[0] }
          it { subject.should match(/checksum=#{checksum}$/) }
        end
      end
    end

    describe "#send_api_request" do
      let(:method) { :join }
      let(:params) { { :param1 => "value1" } }
      let(:data) { "any data" }
      let(:url) { "http://test-server:8080?param1=value1&checksum=12345" }
      let(:make_request) { api.send_api_request(method, params, data) }
      let(:response_mock) { mock() } # mock of what send_request() would return

      before { api.should_receive(:get_url).with(method, params).and_return([url, nil]) }

      context "returns an empty hash if the response body is empty" do
        before do
          api.should_receive(:send_request).with(url, data).and_return(response_mock)
          response_mock.should_receive(:body).and_return("")
        end
        it { make_request.should == { } }
      end

      context "hashfies and validates the response body" do
        before do
          api.should_receive(:send_request).with(url, data).and_return(response_mock)
          response_mock.should_receive(:body).twice.and_return("response-body")
        end

        context "checking if it has a :response key" do
          before { BigBlueButton::BigBlueButtonHash.should_receive(:from_xml).with("response-body").and_return({ }) }
          it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
        end

        context "checking if it the :response key has a :returncode key" do
          before { BigBlueButton::BigBlueButtonHash.should_receive(:from_xml).with("response-body").and_return({ :response => { } }) }
          it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
        end
      end

      context "formats the response hash" do
        let(:response) { { :returncode => "SUCCESS" } }
        let(:formatted_response) { { :returncode => true, :messageKey => "", :message => "" } }
        before do
          api.should_receive(:send_request).with(url, data).and_return(response_mock)
          response_mock.should_receive(:body).twice.and_return("response-body")
          BigBlueButton::BigBlueButtonHash.should_receive(:from_xml).with("response-body").and_return(response)

          # here starts the validation
          # doesn't test the resulting format, only that the formatter was called
          formatter_mock = mock(BigBlueButton::BigBlueButtonFormatter)
          BigBlueButton::BigBlueButtonFormatter.should_receive(:new).with(response).and_return(formatter_mock)
          formatter_mock.should_receive(:default_formatting).and_return(formatted_response)
        end
        it { make_request }
      end

      context "raise an error if the formatted response has no :returncode" do
        let(:response) { { :returncode => true } }
        let(:formatted_response) { { } }
        before do
          api.should_receive(:send_request).with(url, data).and_return(response_mock)
          response_mock.should_receive(:body).twice.and_return("response-body")
          BigBlueButton::BigBlueButtonHash.should_receive(:from_xml).with("response-body").and_return(response)

          formatter_mock = mock(BigBlueButton::BigBlueButtonFormatter)
          BigBlueButton::BigBlueButtonFormatter.should_receive(:new).with(response).and_return(formatter_mock)
          formatter_mock.should_receive(:default_formatting).and_return(formatted_response)
        end
        it { expect { make_request }.to raise_error(BigBlueButton::BigBlueButtonException) }
      end
    end

    describe "#send_request" do
      let(:url) { "http://test-server:8080/res?param1=value1&checksum=12345" }
      let(:url_parsed) { URI.parse(url) }

      before do
        @http_mock = mock(Net::HTTP)
        @http_mock.should_receive(:"open_timeout=").with(api.timeout)
        @http_mock.should_receive(:"read_timeout=").with(api.timeout)
        Net::HTTP.should_receive(:new).with("test-server", 8080).and_return(@http_mock)
      end

      context "standard case" do
        before { @http_mock.should_receive(:get).with("/res?param1=value1&checksum=12345", {}).and_return("ok") }
        it { api.send(:send_request, url).should == "ok" }
      end

      context "handles a TimeoutError" do
        before { @http_mock.should_receive(:get) { raise TimeoutError } }
        it { expect { api.send(:send_request, url) }.to raise_error(BigBlueButton::BigBlueButtonException) }
      end

      context "handles general Exceptions" do
        before { @http_mock.should_receive(:get) { raise Exception } }
        it { expect { api.send(:send_request, url) }.to raise_error(BigBlueButton::BigBlueButtonException) }
      end

      context "post with data" do
        let(:data) { "any data" }
        before {
          path = "/res?param1=value1&checksum=12345"
          opts = { 'Content-Type' => 'application/x-www-form-urlencoded' }
          @http_mock.should_receive(:post).with(path, data, opts).and_return("ok")
        }
        it {
          api.send(:send_request, url, data).should == "ok"
        }
      end

      context "get with headers" do
        let(:headers_hash) { { :anything => "anything" } }
        before { @http_mock.should_receive(:get).with("/res?param1=value1&checksum=12345", headers_hash).and_return("ok") }
        it {
          api.request_headers = headers_hash
          api.send(:send_request, url).should == "ok"
        }
      end

      context "get with headers" do
        let(:headers_hash) { { :anything => "anything" } }
        let(:data) { "any data" }
        before {
          path = "/res?param1=value1&checksum=12345"
          opts = { 'Content-Type' => 'application/x-www-form-urlencoded', :anything => "anything" }
          @http_mock.should_receive(:post).with(path, data, opts).and_return("ok")
        }
        it {
          api.request_headers = headers_hash
          api.send(:send_request, url, data).should == "ok"
        }
      end
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

      context "accepts non standard options" do
        let(:recordIDs) { ["id-1"] }
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        let(:params_out) {
          { :publish => "true", :recordID => "id-1",
            :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:publishRecordings, params_out) }
        it { api.publish_recordings(recordIDs, true, params_in) }
      end
    end

    describe "#delete_recordings" do

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

      context "accepts non standard options" do
        let(:recordIDs) { ["id-1"] }
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        let(:params_out) {
          { :recordID => "id-1", :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:deleteRecordings, params_out) }
        it { api.delete_recordings(recordIDs, params_in) }
      end
    end
  end

  it_should_behave_like "BigBlueButtonApi", "0.8"
  it_should_behave_like "BigBlueButtonApi", "0.81"
  it_should_behave_like "BigBlueButtonApi", "0.9"
  it_should_behave_like "BigBlueButtonApi", "1.0"
end
