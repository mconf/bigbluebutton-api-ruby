require 'spec_helper'

describe BigBlueButton::BigBlueButtonFormatter do

  describe "#hash" do
    subject { BigBlueButton::BigBlueButtonFormatter.new({}) }
    it { subject.should respond_to(:hash) }
    it { subject.should respond_to(:"hash=") }
  end

  describe "#initialize" do
    context "with a hash" do
      let(:hash) { { :param1 => "123", :param2 => 123, :param3 => true } }
      subject { BigBlueButton::BigBlueButtonFormatter.new(hash) }
      it { subject.hash.should == hash }
    end

    context "without a hash" do
      subject { BigBlueButton::BigBlueButtonFormatter.new(nil) }
      it { subject.hash.should == { } }
    end
  end

  describe "#to_string" do
    let(:hash) { { :param1 => "123", :param2 => 123, :param3 => true } }
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new(hash) }
    before {
      formatter.to_string(:param1)
      formatter.to_string(:param2)
      formatter.to_string(:param3)
    }
    it { hash[:param1].should == "123" }
    it { hash[:param2].should == "123" }
    it { hash[:param3].should == "true" }

    context "returns empty string if the param doesn't exists" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => 1 }) }
      it { subject.to_string(:inexistent).should == "" }
    end

    context "returns empty string if the hash is nil" do
      subject { BigBlueButton::BigBlueButtonFormatter.new(nil) }
      it { subject.to_string(:inexistent).should == "" }
    end
  end

  describe "#to_boolean" do
    let(:hash) { { :true1 => "TRUE", :true2 => "true", :false1 => "FALSE", :false2 => "false" } }
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new(hash) }
    before {
      formatter.to_boolean(:true1)
      formatter.to_boolean(:true2)
      formatter.to_boolean(:false1)
      formatter.to_boolean(:false2)
    }
    it { hash[:true1].should be_true }
    it { hash[:true2].should be_true }
    it { hash[:false1].should be_false }
    it { hash[:false2].should be_false }

    context "returns false if the param doesn't exists" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => 1}) }
      it { subject.to_boolean(:inexistent).should == false }
    end

    context "returns false if the hash is nil" do
      subject { BigBlueButton::BigBlueButtonFormatter.new(nil) }
      it { subject.to_boolean(:inexistent).should == false }
    end
  end

  describe "#to_datetime" do
    let(:hash) {
      { :param1 => "Thu Sep 01 17:51:42 UTC 2011",
        :param2 => "Thu Sep 08",
        :param3 => 1315254777880,
        :param4 => "1315254777880",
        :param5 => "0",
        :param6 => 0,
        :param7 => "NULL",
        :param8 => nil
      }
    }
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new(hash) }
    before {
      formatter.to_datetime(:param1)
      formatter.to_datetime(:param2)
      formatter.to_datetime(:param3)
      formatter.to_datetime(:param4)
      formatter.to_datetime(:param5)
      formatter.to_datetime(:param6)
      formatter.to_datetime(:param7)
    }
    it { hash[:param1].should == DateTime.parse("Thu Sep 01 17:51:42 UTC 2011") }
    it { hash[:param2].should == DateTime.parse("Thu Sep 08") }
    it { hash[:param3].should == DateTime.parse("2011-09-05 17:32:57 -0300") }
    it { hash[:param4].should == DateTime.parse("2011-09-05 17:32:57 -0300") }
    it { hash[:param5].should == nil }
    it { hash[:param6].should == nil }
    it { hash[:param7].should == nil }
    it { hash[:param8].should == nil }

    context "returns nil if the param doesn't exists" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => 1}) }
      it { subject.to_datetime(:inexistent).should == nil }
    end

    context "returns nil if the hash is nil" do
      subject { BigBlueButton::BigBlueButtonFormatter.new(nil) }
      it { subject.to_datetime(:inexistent).should == nil }
    end
  end

  describe "#to_sym" do
    let(:hash) { { :param1 => :sym1, :param2 => "sym2", :param3 => "SyM3" } }
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new(hash) }
    before {
      formatter.to_sym(:param1)
      formatter.to_sym(:param2)
      formatter.to_sym(:param3)
    }
    it { hash[:param1].should == :sym1 }
    it { hash[:param2].should == :sym2 }
    it { hash[:param3].should == :sym3 }

    context "returns empty string if the param doesn't exists" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => 1 }) }
      it { subject.to_string(:inexistent).should == "" }
    end

    context "returns empty string if the hash is nil" do
      subject { BigBlueButton::BigBlueButtonFormatter.new(nil) }
      it { subject.to_string(:inexistent).should == "" }
    end

    context "returns empty string if the value to be converted is an empty string" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => "" }) }
      it { subject.to_string(:param).should == "" }
    end
  end

  describe "#to_int" do
    let(:hash) { { :param1 => 5, :param2 => "5" } }
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new(hash) }
    before {
      formatter.to_int(:param1)
      formatter.to_int(:param2)
    }
    it { hash[:param1].should == 5 }
    it { hash[:param2].should == 5 }

    context "returns 0 if the param doesn't exists" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => 1 }) }
      it { subject.to_int(:inexistent).should == 0 }
    end

    context "returns 0 if the hash is nil" do
      subject { BigBlueButton::BigBlueButtonFormatter.new(nil) }
      it { subject.to_int(:inexistent).should == 0 }
    end

    context "returns 0 if the value to be converted is invalid" do
      subject { BigBlueButton::BigBlueButtonFormatter.new({ :param => "invalid" }) }
      it { subject.to_int(:param).should == 0 }
    end
  end

  describe "#default_formatting" do
    let(:input) { { :returncode => "SUCCESS", :messageKey => "mkey", :message => "m" } }
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new(input) }

    context "standard case" do
      let(:expected_output) { { :returncode => true, :messageKey => "mkey", :message => "m" } }
      subject { formatter.default_formatting }
      it { subject.should == expected_output }
    end

    context "when :returncode should be false" do
      before { input[:returncode] = "ERROR" }
      subject { formatter.default_formatting }
      it { subject[:returncode].should be_false }
    end

    context "when :messageKey is empty" do
      before { input[:messageKey] = {} }
      subject { formatter.default_formatting }
      it { subject[:messageKey].should == "" }
    end

    context "when :messageKey is nil" do
      before { input.delete(:messageKey) }
      subject { formatter.default_formatting }
      it { subject[:messageKey].should == "" }
    end

    context "when :message is empty" do
      before { input[:message] = {} }
      subject { formatter.default_formatting }
      it { subject[:message].should == "" }
    end

    context "when there's no :message key" do
      before { input.delete(:message) }
      subject { formatter.default_formatting }
      it { subject[:message].should == "" }
    end
  end

  describe ".format_meeting" do
    let(:hash) {
      { :meetingID => 123, :meetingName => 123, :moderatorPW => 111, :attendeePW => 222,
        :hasBeenForciblyEnded => "FALSE", :running => "TRUE", :createTime => "123456789",
        :dialNumber => 1234567890, :voiceBridge => "12345",
        :participantCount => "10", :listenerCount => "3", :videoCount => "5" }
    }

    subject { BigBlueButton::BigBlueButtonFormatter.format_meeting(hash) }
    it { subject[:meetingID].should == "123" }
    it { subject[:meetingName].should == "123" }
    it { subject[:moderatorPW].should == "111" }
    it { subject[:attendeePW].should == "222" }
    it { subject[:hasBeenForciblyEnded].should == false }
    it { subject[:running].should == true }
    it { subject[:createTime].should == 123456789 }
    it { subject[:voiceBridge].should == 12345 }
    it { subject[:dialNumber].should == "1234567890" }
    it { subject[:participantCount].should == 10 }
    it { subject[:listenerCount].should == 3 }
    it { subject[:videoCount].should == 5 }
  end

  describe ".format_attendee" do
    let(:hash) { { :userID => 123, :fullName => "Cameron", :role => "VIEWER" } }

    subject { BigBlueButton::BigBlueButtonFormatter.format_attendee(hash) }
    it { subject[:userID].should == "123" }
    it { subject[:fullName].should == "Cameron" }
    it { subject[:role].should == :viewer }
  end

  describe ".format_recording" do
    let(:hash) {
      { :recordID => 123, :meetingID => 123, :name => 123, :published => "true",
        :startTime => "Thu Mar 04 14:05:56 UTC 2010",
        :endTime => "Thu Mar 04 15:01:01 UTC 2010",
        :metadata => {
          :title => "Test Recording",
          :empty1 => nil,
          :empty2 => {},
          :empty3 => [],
          :empty4 => " ",
          :empty5 => "\n\t"
        },
        :playback => {
          :format => [
            { :type => "simple",
              :url => "http://server.com/simple/playback?recordID=183f0bf3a0982a127bdb8161-1",
              :length => "62" },
            { :type => "simple",
              :url => "http://server.com/simple/playback?recordID=183f0bf3a0982a127bdb8161-1",
              :length => "48" }
          ]
        }
      }
    }

    context do
      subject { BigBlueButton::BigBlueButtonFormatter.format_recording(hash) }
      it { subject[:recordID].should == "123" }
      it { subject[:meetingID].should == "123" }
      it { subject[:name].should == "123" }
      it { subject[:startTime].should == DateTime.parse("Thu Mar 04 14:05:56 UTC 2010") }
      it { subject[:endTime].should == DateTime.parse("Thu Mar 04 15:01:01 UTC 2010") }
      it { subject[:playback][:format][0][:length].should == 62 }
      it { subject[:metadata][:empty1].should == "" }
      it { subject[:metadata][:empty2].should == "" }
      it { subject[:metadata][:empty3].should == "" }
      it { subject[:metadata][:empty4].should == "" }
      it { subject[:metadata][:empty5].should == "" }
    end

    context "doesn't fail without playback formats" do
      before { hash.delete(:playback) }
      subject { BigBlueButton::BigBlueButtonFormatter.format_recording(hash) }
      it { subject[:playback].should == nil }
    end
  end

  describe "#flatten_objects" do
    let(:formatter) { BigBlueButton::BigBlueButtonFormatter.new({ }) }

    context "standard case" do
      context "when the target key is empty" do
        let(:hash) { { :objects => {} } }
        before { formatter.hash = hash }
        subject { formatter.flatten_objects(:objects, :object) }
        it { subject.should == { :objects => [] } }
      end

      context "when the target key doesn't exist in the hash" do
        let(:hash) { { } }
        before { formatter.hash = hash }
        subject { formatter.flatten_objects(:objects, :object) }
        it { subject.should == { :objects => [] } } # adds the one the doesn't exist
      end

      context "when there's only one object in the list" do
        let(:object_hash) { { :id => 1 } }
        let(:hash) { { :objects => { :object => object_hash } } }
        before { formatter.hash = hash }
        subject { formatter.flatten_objects(:objects, :object) }
        it { subject.should == { :objects => [ object_hash ] } }
      end

      context "when there are several objects in the list" do
        let(:object_hash1) { { :id => 1 } }
        let(:object_hash2) { { :id => 2 } }
        let(:hash) { { :objects => { :object => [ object_hash1, object_hash2 ] } } }
        before { formatter.hash = hash }
        subject { formatter.flatten_objects(:objects, :object) }
        it { subject.should == { :objects => [ object_hash1, object_hash2 ] } }
      end
    end

    context "using different keys" do
      let(:hash1) { { :any => 1 } }
      let(:hash2) { { :any => 2 } }
      let(:collection_hash) { { :foos => { :bar => [ hash1, hash2 ] } } }
      before { formatter.hash = collection_hash }
      subject { formatter.flatten_objects(:foos, :bar) }
      it { subject.should == { :foos => [ hash1, hash2 ] } }
    end

  end


end
