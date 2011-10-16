require 'spec_helper'
require 'tempfile'

describe BigBlueButton::BigBlueButtonModules do
  let(:modules) { BigBlueButton::BigBlueButtonModules.new }

  describe "#presentation_urls" do
    subject { modules }
    it { should respond_to(:presentation_urls) }
    it { should respond_to("presentation_urls=") }
  end

  describe "#presentation_files" do
    subject { modules }
    it { should respond_to(:presentation_files) }
    it { should respond_to("presentation_files=") }
  end

  describe "#presentation_base64s" do
    subject { modules }
    it { should respond_to(:presentation_base64s) }
    it { should respond_to("presentation_base64s=") }
  end

  describe "#add_presentation" do
    context "when type = :url" do
      before {
        modules.add_presentation(:url, "http://anything")
        modules.add_presentation(:url, "http://anything2")
      }
      it { modules.presentation_urls.size.should == 2 }
      it { modules.presentation_urls.first.should == "http://anything" }
      it { modules.presentation_urls.last.should == "http://anything2" }
    end

    context "when type = :file" do
      before {
        modules.add_presentation(:file, "myfile.ppt")
        modules.add_presentation(:file, "myfile2.ppt")
      }
      it { modules.presentation_files.size.should == 2 }
      it { modules.presentation_files.first.should == "myfile.ppt" }
      it { modules.presentation_files.last.should == "myfile2.ppt" }
    end

    context "when type = :base64" do
      before {
        modules.add_presentation(:base64, "1234567890", "file1.pdf")
        modules.add_presentation(:base64, "0987654321", "file2.pdf")
      }
      it { modules.presentation_base64s.size.should == 2 }
      it { modules.presentation_base64s.first.should == ["file1.pdf", "1234567890"] }
      it { modules.presentation_base64s.last.should == ["file2.pdf", "0987654321"] }
    end
  end

  describe "#to_xml" do
    context "when nothing was added" do
      it { modules.to_xml.should == "" }
    end

    context "with presentations" do
      let(:file) {
        f = Tempfile.new(['file1', '.pdf'])
        f.write("First\nSecond")
        f.close
        f
      }
      let(:file_encoded) {
        File.open(file.path, "r") do |f|
          Base64.encode64(f.read)
        end
      }
      let(:xml) {
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" +
        "<modules>" +
          "<module name=\"presentation\">" +
            "<document url=\"http://anything\" />" +
            "<document url=\"http://anything2\" />" +
            "<document name=\"file1.pdf\">1234567890</document>" +
            "<document name=\"#{File.basename(file.path)}\">#{file_encoded}</document>" +
          "</module>" +
        "</modules>"
      }
      before {
        modules.add_presentation(:url, "http://anything")
        modules.add_presentation(:url, "http://anything2")
        modules.add_presentation(:base64, "1234567890", "file1.pdf")
        modules.add_presentation(:file, file.path)
      }
      it { modules.to_xml.should == xml }
    end
  end

end
