require 'spec_helper'

describe BigBlueButton::BigBlueButtonException do

  describe "#key" do
    subject { BigBlueButton::BigBlueButtonException.new }
    it { should respond_to(:key) }
    it { should respond_to("key=") }
  end

  describe "#to_s" do
    context "when key is set" do
      let(:api) { BigBlueButton::BigBlueButtonException.new("super-msg") }
      before { api.key = "key-msg" }
      it { api.to_s.should == "super-msg, messageKey: key-msg" }
    end

    context "when key is not set" do
      let(:api) { BigBlueButton::BigBlueButtonException.new("super-msg") }
      before { api.key = nil }
      it { api.to_s.should == "super-msg" }
    end
  end

end
