require 'spec_helper'

describe BigBlueButton::BigBlueButtonConfigLayout do

  let(:default_xml) { # a simplified layouts.xml file
    "<layouts>
       <layout name=\"Default\" default=\"true\">
         <window name=\"NotesWindow\" hidden=\"true\" width=\"0.7\" height=\"1\" x=\"0\" y=\"0\" draggable=\"false\" resizable=\"false\"/>
       </layout>
       <layout name=\"Video Chat\">
         <window name=\"NotesWindow\" hidden=\"true\" width=\"0.7\" height=\"1\" x=\"0\" y=\"0\" draggable=\"false\" resizable=\"false\"/>
       </layout>
     </layouts>"
  }

  describe "#initialize" do
    context "with a valid xml" do
      before {
        XmlSimple.should_receive(:xml_in)
          .with(default_xml, { 'ForceArray' => false, 'KeepRoot' => true })
          .and_return("internal_xml")
      }
      subject { BigBlueButton::BigBlueButtonConfigLayout.new(default_xml) }
      it("creates and stores a correct internal xml") { subject.xml.should eql("internal_xml") }
    end

    context "with an empty string as xml" do
      it "throws an exception" do
        expect {
          BigBlueButton::BigBlueButtonConfigLayout.new("")
        }.to raise_error(BigBlueButton::BigBlueButtonException)
      end
    end

    context "throws any exception thrown by XmlSimple" do
      before {
        XmlSimple.should_receive(:xml_in) { raise Exception }
      }
      it {
        expect {
          BigBlueButton::BigBlueButtonConfigLayout.new(default_xml)
        }.to raise_error(BigBlueButton::BigBlueButtonException)
      }
    end
  end

  describe "#get_available_layouts" do
    subject { target.get_available_layouts }

    context "returns nil if the xml has no <layouts>" do
      let(:target) { BigBlueButton::BigBlueButtonConfigLayout.new("<test></test>") }
      it { should be_nil }
    end

    context "returns nil if the xml has no <layouts><layout>" do
      let(:target) { BigBlueButton::BigBlueButtonConfigLayout.new("<layouts></layouts>") }
      it { should be_nil }
    end

    context "returns the correct available layout names" do
      let(:target) { BigBlueButton::BigBlueButtonConfigLayout.new(default_xml) }
      it { should be_instance_of(Array) }
      it { subject.count.should be(2) }
      it { should include("Default") }
      it { should include("Video Chat") }
    end

    context "doesn't return duplicated layouts" do
      let(:layouts_xml) {
        "<layouts>
           <layout name=\"Default\" default=\"true\">
             <window name=\"NotesWindow\" hidden=\"true\" width=\"0.7\" height=\"1\" x=\"0\" y=\"0\" draggable=\"false\" resizable=\"false\"/>
           </layout>
           <layout name=\"Default\">
             <window name=\"NotesWindow\" hidden=\"true\" width=\"0.7\" height=\"1\" x=\"0\" y=\"0\" draggable=\"false\" resizable=\"false\"/>
           </layout>
         </layouts>"
      }
      let(:target) { BigBlueButton::BigBlueButtonConfigLayout.new(layouts_xml) }
      it { should be_instance_of(Array) }
      it { subject.count.should be(1) }
      it { should include("Default") }
    end
  end

end
