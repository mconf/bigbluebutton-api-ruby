require 'spec_helper'

describe BigBlueButton::BigBlueButtonFormatter do

  describe ".default_formatting" do
    let(:input) { { :response => { :returncode => "SUCCESS", :messageKey => "mkey", :message => "m" } } }

    context "standard case" do
      let(:expected_output) { { :returncode => true, :messageKey => "mkey", :message => "m" } }
      subject { BigBlueButton::BigBlueButtonFormatter.default_formatting(input) }
      it { subject.should == expected_output }
    end

    context "when :returncode should be false" do
      before { input[:response][:returncode] = "ERROR" }
      subject { BigBlueButton::BigBlueButtonFormatter.default_formatting(input) }
      it { subject[:returncode].should be_false }
    end

    context "when :messageKey is empty" do
      before { input[:response][:messageKey] = {} }
      subject { BigBlueButton::BigBlueButtonFormatter.default_formatting(input) }
      it { subject[:messageKey].should == "" }
    end

    context "when :messageKey is nil" do
      before { input[:response].delete(:messageKey) }
      subject { BigBlueButton::BigBlueButtonFormatter.default_formatting(input) }
      it { subject[:messageKey].should == "" }
    end

    context "when :message is empty" do
      before { input[:response][:message] = {} }
      subject { BigBlueButton::BigBlueButtonFormatter.default_formatting(input) }
      it { subject[:message].should == "" }
    end

    context "when there's no :message key" do
      before { input[:response].delete(:message) }
      subject { BigBlueButton::BigBlueButtonFormatter.default_formatting(input) }
      it { subject[:message].should == "" }
    end
  end

end
