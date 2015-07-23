require 'spec_helper'

describe BigBlueButton::BigBlueButtonConfigXml do

  let(:default_xml) { # a simplified config.xml file
    "<config>
       <help url=\"http://test-server.org/help.html\"/>
       <modules>
         <module name=\"LayoutModule\" url=\"http://test-server.org/client/LayoutModule.swf?v=4357\"
                 uri=\"rtmp://test-server.org/bigbluebutton\"
                 layoutConfig=\"http://test-server.org/client/conf/layout.xml\"
                 enableEdit=\"false\"/>
       </modules>
     </config>"
  }

  let(:complex_xml) {
    "<config>\
       <localeversion suppressWarning=\"false\">0.8</localeversion>\
       <version>4357-2014-02-06</version>\
       <help url=\"http://test-server.org/help.html\"/>\
       <javaTest url=\"http://test-server.org/testjava.html\"/>\
       <modules>
         <module name=\"ChatModule\" url=\"http://test-server.org/client/ChatModule.swf\"
                 uri=\"rtmp://test-server.org/bigbluebutton\"
                 dependsOn=\"UsersModule\" translationOn=\"false\"
                 translationEnabled=\"false\" privateEnabled=\"true\"
                 position=\"top-right\" baseTabIndex=\"701\"/>
         <module name=\"UsersModule\" url=\"http://test-server.org/client/UsersModule.swf\"
                 uri=\"rtmp://test-server.org/bigbluebutton\"
                 allowKickUser=\"true\" enableRaiseHand=\"true\"
                 enableSettingsButton=\"true\" baseTabIndex=\"301\"/>
         <module name=\"LayoutModule\" url=\"http://test-server.org/client/LayoutModule.swf?v=4357\"
                 uri=\"rtmp://test-server.org/bigbluebutton\"
                 layoutConfig=\"http://test-server.org/client/conf/layout.xml\"
                 enableEdit=\"false\"/>
       </modules>
     </config>"
  }

  describe "#initialize" do
    context "with a valid xml" do
      before {
        XmlSimple.should_receive(:xml_in)
          .with(default_xml, { 'ForceArray' => false, 'KeepRoot' => true })
          .and_return("response")
      }
      subject { BigBlueButton::BigBlueButtonConfigXml.new(default_xml) }
      it("creates and stores a correct internal xml") { subject.xml.should eql("response") }
    end

    context "with an empty string as xml" do
      it "throws an exception" do
        expect {
          BigBlueButton::BigBlueButtonConfigXml.new("")
        }.to raise_error(BigBlueButton::BigBlueButtonException)
      end
    end

    context "throws any exception thrown by XmlSimple" do
      before {
        XmlSimple.should_receive(:xml_in) { raise Exception }
      }
      it {
        expect {
          BigBlueButton::BigBlueButtonConfigXml.new(default_xml)
        }.to raise_error(BigBlueButton::BigBlueButtonException)
      }
    end
  end

  describe "#get_attribute" do
    let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(default_xml) }

    context "searching inside a module" do
      context "if the xml has no <config>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<any></any>") }
        subject { target.get_attribute("LayoutModule", "layoutConfig") }
        it { should be_nil }
      end

      context "if the xml has no <config><modules>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<config></config>") }
        subject { target.get_attribute("LayoutModule", "layoutConfig") }
        it { should be_nil }
      end

      context "if the xml has no <config><modules><module>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<config><modules></modules></config>") }
        subject { target.get_attribute("LayoutModule", "layoutConfig") }
        it { should be_nil }
      end

      context "if the module and attribute are found" do
        subject { target.get_attribute("LayoutModule", "layoutConfig") }
        it { should eql("http://test-server.org/client/conf/layout.xml") }
      end

      context "if the module is not found" do
        subject { target.get_attribute("InexistentModule", "layoutConfig") }
        it { should be_nil }
      end

      context "if the attribute is not found" do
        subject { target.get_attribute("LayoutModule", "inexistentAttribute") }
        it { should be_nil }
      end

      # just to make sure it won't break in a more complete config.xml
      context "works with a complex xml" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(complex_xml) }
        subject { target.get_attribute("LayoutModule", "layoutConfig") }
        it { should eql("http://test-server.org/client/conf/layout.xml") }
      end
    end

    context "searching outside a module" do
      context "if the xml has no <config>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<any></any>") }
        subject { target.get_attribute("help", "url", false) }
        it { should be_nil }
      end

      context "if the tag and attribute are found" do
        subject { target.get_attribute("help", "url", false) }
        it { should eql("http://test-server.org/help.html") }
      end

      context "if the tag is not found" do
        subject { target.get_attribute("inexistent", "url", false) }
        it { should be_nil }
      end

      context "if the attribute is not found" do
        subject { target.get_attribute("help", "inexistent", false) }
        it { should be_nil }
      end

      # just to make sure it won't break in a more complete config.xml
      context "works with a complex xml" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(complex_xml) }
        subject { target.get_attribute("help", "url", false) }
        it { should eql("http://test-server.org/help.html") }
      end
    end
  end

  describe "#set_attribute" do
    let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(default_xml) }

    context "setting an attribute inside a module" do
      context "if the xml has no <config>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<any></any>") }
        subject { target.set_attribute("LayoutModule", "layoutConfig", "value") }
        it { should be_nil }
      end

      context "if the xml has no <config><modules>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<config></config>") }
        subject { target.set_attribute("LayoutModule", "layoutConfig", "value") }
        it { should be_nil }
      end

      context "if the xml has no <config><modules><module>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<config><modules></modules></config>") }
        subject { target.set_attribute("LayoutModule", "layoutConfig", "value") }
        it { should be_nil }
      end

      context "if the module and attribute are found" do
        context "setting an attribute as string" do
          before(:each) {
            target.set_attribute("LayoutModule", "layoutConfig", "value").should eql("value")
          }
          it { target.get_attribute("LayoutModule", "layoutConfig").should eql("value") }
        end

        context "sets values always as string" do
          context "boolean" do
            before(:each) {
              target.set_attribute("LayoutModule", "layoutConfig", true).should eql("true")
            }
            it { target.get_attribute("LayoutModule", "layoutConfig").should eql("true") }
          end

          context "Hash" do
            before(:each) {
              target.set_attribute("LayoutModule", "layoutConfig", {}).should eql("{}")
            }
            it { target.get_attribute("LayoutModule", "layoutConfig").should eql("{}") }
          end
        end
      end

      context "if the module is not found" do
        subject { target.set_attribute("InexistentModule", "layoutConfig", "value") }
        it { should be_nil }
      end

      context "if the attribute is not found" do
        subject { target.set_attribute("LayoutModule", "inexistentAttribute", "value") }
        it { should be_nil }
      end

      # just to make sure it won't break in a more complete config.xml
      context "works with a complex xml" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(complex_xml) }
        before(:each) {
          target.set_attribute("LayoutModule", "layoutConfig", "value").should eql("value")
        }
        it { target.get_attribute("LayoutModule", "layoutConfig").should eql("value") }
      end
    end

    context "setting an attribute outside of a module" do
      context "if the xml has no <config>" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new("<any></any>") }
        subject { target.set_attribute("help", "url", "value", false) }
        it { should be_nil }
      end

      context "if the module and attribute are found" do
        before(:each) {
          target.set_attribute("help", "url", "value", false).should eql("value")
        }
        it { target.get_attribute("help", "url", false).should eql("value") }
      end

      context "if the module is not found" do
        subject { target.set_attribute("InexistentModule", "url", "value", false) }
        it { should be_nil }
      end

      context "if the attribute is not found" do
        subject { target.set_attribute("help", "inexistentAttribute", "value", false) }
        it { should be_nil }
      end

      # just to make sure it won't break in a more complete config.xml
      context "works with a complex xml" do
        let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(complex_xml) }
        before(:each) {
          target.set_attribute("help", "url", "value", false).should eql("value")
        }
        it { target.get_attribute("help", "url", false).should eql("value") }
      end
    end

  end

  describe "#as_string" do
    context "for a simple xml" do
      let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(default_xml) }
      subject { target.as_string }
      it {
        # it is the same XML as `default_xml`, just formatted slightly differently
        expected = "<config><help url=\"http://test-server.org/help.html\" /><modules><module name=\"LayoutModule\" url=\"http://test-server.org/client/LayoutModule.swf?v=4357\" uri=\"rtmp://test-server.org/bigbluebutton\" layoutConfig=\"http://test-server.org/client/conf/layout.xml\" enableEdit=\"false\" /></modules></config>"
        should eql(expected)
      }
    end

    context "for a complex xml" do
      let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(complex_xml) }
      subject { target.as_string }
      it {
        # it is the same XML as `default_xml`, just formatted slightly differently
        expected = "<config version=\"4357-2014-02-06\"><localeversion suppressWarning=\"false\">0.8</localeversion><help url=\"http://test-server.org/help.html\" /><javaTest url=\"http://test-server.org/testjava.html\" /><modules><module name=\"ChatModule\" url=\"http://test-server.org/client/ChatModule.swf\" uri=\"rtmp://test-server.org/bigbluebutton\" dependsOn=\"UsersModule\" translationOn=\"false\" translationEnabled=\"false\" privateEnabled=\"true\" position=\"top-right\" baseTabIndex=\"701\" /><module name=\"UsersModule\" url=\"http://test-server.org/client/UsersModule.swf\" uri=\"rtmp://test-server.org/bigbluebutton\" allowKickUser=\"true\" enableRaiseHand=\"true\" enableSettingsButton=\"true\" baseTabIndex=\"301\" /><module name=\"LayoutModule\" url=\"http://test-server.org/client/LayoutModule.swf?v=4357\" uri=\"rtmp://test-server.org/bigbluebutton\" layoutConfig=\"http://test-server.org/client/conf/layout.xml\" enableEdit=\"false\" /></modules></config>"
        should eql(expected)
      }
    end
  end

  describe "#is_modified?" do
    let(:target) { BigBlueButton::BigBlueButtonConfigXml.new(default_xml) }

    context "before any attribute is set" do
      it { target.is_modified?.should be_false }
    end

    context "after setting an attribute" do
      before(:each) { target.set_attribute("LayoutModule", "layoutConfig", "value") }
      it { target.is_modified?.should be_true }
    end

    context "if an attribute is set to the same value it already had" do
      before(:each) {
        value = target.get_attribute("LayoutModule", "layoutConfig")
        target.set_attribute("LayoutModule", "layoutConfig", value)
      }
      it { target.is_modified?.should be_false }
    end

    context "if an attribute is set to the same value it already had, but with a different type" do
      before(:each) {
        # it's already false in the original XML, but as a string, not boolean
        target.set_attribute("LayoutModule", "enableEdit", false)
      }
      it { target.is_modified?.should be_false }
    end
  end

end
