require 'spec_helper'

# Tests for BBB API version 0.81
describe BigBlueButton::BigBlueButtonApi do

  # default variables and API object for all tests
  let(:url) { "http://server.com" }
  let(:secret) { "1234567890abcdefghijkl" }
  let(:version) { "0.81" }
  let(:debug) { false }
  let(:api) { BigBlueButton::BigBlueButtonApi.new(url, secret, version, debug) }

  describe "#get_default_config_xml" do
    let(:response) { "<response><returncode>1</returncode></response>" }
    let(:response_asObject) { {"response" => {"returncode" => "1" } } }

    context "with response as a string" do
      context "and without non standard options" do
        before { api.should_receive(:send_api_request).with(:getDefaultConfigXML, {}, nil, true).and_return(response) }
        it { api.get_default_config_xml() }
        it { api.get_default_config_xml().should == response }
        it { api.get_default_config_xml(false).should_not == response_asObject }
      end

      context "and with non standard options" do
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:getDefaultConfigXML, params_in, nil, true).and_return(response) }
        it { api.get_default_config_xml(false, params_in) }
        it { api.get_default_config_xml(false, params_in).should == response }
        it { api.get_default_config_xml(false, params_in).should_not == response_asObject }
      end
    end

    context "with response as a object" do
      context "and without non standard options" do
        before { api.should_receive(:send_api_request).with(:getDefaultConfigXML, {}, nil, true).and_return(response) }
        it { api.get_default_config_xml(true) }
        it { api.get_default_config_xml(true).should == response_asObject }
        it { api.get_default_config_xml(true).should_not == response }
      end

      context "and with non standard options" do
        let(:params_in) {
          { :anything1 => "anything-1", :anything2 => 2 }
        }
        before { api.should_receive(:send_api_request).with(:getDefaultConfigXML, params_in, nil, true).and_return(response) }
        it { api.get_default_config_xml(true, params_in) }
        it { api.get_default_config_xml(true, params_in).should == response_asObject }
        it { api.get_default_config_xml(true, params_in).should_not == response }
      end
    end
  end

  describe "#set_config_xml" do
    let(:configToken) { "asdfl234kjasdfsadfy" }
    let(:meeting_id) { "meeting-id" }
    let(:xml) { "<response><returncode>SUCCESS</returncode><configToken>asdfl234kjasdfsadfy</configToken></response>" }
    let(:response) {
      { :returncode => "SUCCESS", :configToken => configToken }
    }

    context "without non standard options" do
      let(:params) {
        { :meetingID => meeting_id, :configXML => xml }
      }

      before { api.should_receive(:send_api_request).with(:setConfigXML, params, xml).and_return(response) }
      it { api.set_config_xml(meeting_id, xml) }
      it { api.set_config_xml(meeting_id, xml).should == configToken }
    end

    context "with non standard options" do
      let(:params_in) {
        { :anything1 => "anything-1", :anything2 => 2 }
      }
      let(:params_out) {
        { :meetingID => meeting_id, :configXML => xml, :anything1 => "anything-1", :anything2 => 2 }
      }

      before { api.should_receive(:send_api_request).with(:setConfigXML, params_out, xml).and_return(response) }
      it { api.set_config_xml(meeting_id, xml, params_in) }
      it { api.set_config_xml(meeting_id, xml, params_in).should == configToken }
    end
  end

  describe "#get_available_layouts" do
    let(:config_xml) { # a simplified config.xml file
      "<config>
         <modules>
           <module name=\"LayoutModule\" url=\"http://test-server.org/client/LayoutModule.swf?v=4357\"
                   uri=\"rtmp://test-server.org/bigbluebutton\"
                   layoutConfig=\"http://test-server.org/client/conf/layout.xml\"
                   enableEdit=\"false\"/>
         </modules>
       </config>"
    }
    let(:layouts_xml) { # a simplified layouts.xml file
      "<layouts>
         <layout name=\"Default\" default=\"true\">
           <window name=\"NotesWindow\" hidden=\"true\" width=\"0.7\" height=\"1\" x=\"0\" y=\"0\" draggable=\"false\" resizable=\"false\"/>
         </layout>
         <layout name=\"Video Chat\">
           <window name=\"NotesWindow\" hidden=\"true\" width=\"0.7\" height=\"1\" x=\"0\" y=\"0\" draggable=\"false\" resizable=\"false\"/>
         </layout>
       </layouts>"
    }

    context "when an XML is passed" do
      before {
        response = double("Net::HTTPResponse")
        response.stub(:body).and_return(layouts_xml)
        api.should_receive(:send_request)
          .with("http://test-server.org/client/conf/layout.xml")
          .and_return(response)
      }
      subject { api.get_available_layouts(config_xml) }
      it { should be_instance_of(Array) }
      it { subject.count.should be(2) }
      it { should include("Default") }
      it { should include("Video Chat") }
    end

    context "when no XML is passed" do
      before {
        api.should_receive(:get_default_config_xml)
          .and_return(config_xml)
        response = double("Net::HTTPResponse")
        response.stub(:body).and_return(layouts_xml)
        api.should_receive(:send_request)
          .with("http://test-server.org/client/conf/layout.xml")
          .and_return(response)
      }
      subject { api.get_available_layouts }
      it { should be_instance_of(Array) }
      it { subject.count.should be(2) }
      it { should include("Default") }
      it { should include("Video Chat") }
    end
  end

  describe "#get_default_layouts" do
    subject { api.get_default_layouts }
    it { should be_instance_of(Array) }
    it { should include("Default") }
    it { should include("Video Chat") }
    it { should include("Meeting") }
    it { should include("Webinar") }
    it { should include("Lecture assistant") }
    it { should include("Lecture") }
  end

end
