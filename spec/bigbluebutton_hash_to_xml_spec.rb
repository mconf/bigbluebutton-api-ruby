require 'spec_helper'

describe BigBlueButton::BigBlueButtonHash do

  describe ".from_xml" do
    it "simple example" do
      xml = "<response><returncode>1</returncode></response>"
      hash = { :returncode => "1" }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end

    it "maintains all values as strings" do
      xml = "<parent>" \
            "  <node1>1</node1>" \
            "  <node2>string</node2>" \
            "  <node3>true</node3>" \
            "</parent>"
      hash = { :node1 => "1", :node2 => "string", :node3 => "true" }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end

    it "works for xmls with multiple levels" do
      xml = "<parent>" \
            "  <node1>" \
            "    <node2>" \
            "      <node3>true</node3>" \
            "    </node2>" \
            "  </node1>" \
            "</parent>"
      hash = { :node1 => { :node2 => { :node3 => "true" } } }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end

    it "transforms CDATA fields to string" do
      xml = "<parent>" \
            "  <name><![CDATA[Evening Class]]></name>" \
            "  <course><![CDATA[Advanced Ruby]]></course>" \
            "</parent>"
      hash = { :name => "Evening Class", :course => "Advanced Ruby" }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end

    it "transforms duplicated keys in arrays" do
      xml = "<parent>" \
            "  <meetings>" \
            "    <meeting>1</meeting>" \
            "    <meeting>2</meeting>" \
            "    <meeting><details>3</details></meeting>" \
            "    <other>4</other>" \
            "  </meetings>" \
            "</parent>"
      hash = { :meetings => { :meeting => [ "1", "2", { :details => "3" } ],
                              :other => "4" } }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end

    it "works with attributes" do
      xml = "<parent>" \
            "  <meeting attr1=\"v1\">1</meeting>" \
            "</parent>"
      hash = { :meeting => { :attr1 => "v1", :content => "1" } }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end

    it "complex real example" do
      xml = File.open("spec/data/hash_to_xml_complex.xml")

      hash = { :returncode => "SUCCESS",
               :recordings =>
                 { :recording => [
                   { :recordID => "7f5745a08b24fa27551e7a065849dda3ce65dd32-1321618219268",
                     :meetingID => "bd1811beecd20f24314819a52ec202bf446ab94b",
                     :name => "Evening Class1",
                     :published => "true",
                     :startTime => "Fri Nov 18 12:10:23 UTC 2011",
                     :endTime => "Fri Nov 18 12:12:25 UTC 2011",
                     :metadata =>
                       { :course => "Fundamentals Of JAVA",
                         :description => "List of recordings",
                         :activity => "Evening Class1" },
                     :playback =>
                       { :format =>
                         { :type => "slides",
                           :url => "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=7f5745",
                           :length => "3" }
                       }
                   },
                   { :recordID => "6c1d35b82e2552bb254d239540e4f994c4a77367-1316717270941",
                     :meetingID => "585a44eb32b526b100e12b7b755d971fbbd19ab0",
                     :name => "Test de fonctionnalit&#xe9;",
                     :published => "false",
                     :startTime => "2011-09-22 18:47:55 UTC",
                     :endTime => "2011-09-22 19:08:35 UTC",
                     :metadata =>
                       { :course => "Ressources technologiques",
                         :activity => "Test de fonctionnalit&#xe9;",
                         :recording => "true" },
                     :playback =>
                       { :format =>
                         { :type => "slides",
                           :url =>  "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=6c1d35",
                           :length => "0" }
                       }
                   } ]
                 }
      }
      BigBlueButton::BigBlueButtonHash.from_xml(xml).should == hash
    end
  end

  describe ".symbolize_keys" do
    it "converts string-keys to symbols" do
      before = { "one" => 1, "two" => 2, "three" => 3 }
      after = { :one => 1, :two => 2, :three => 3 }
      BigBlueButton::BigBlueButtonHash.symbolize_keys(before).should == after
    end

    it "maintains case" do
      before = { "One" => 1, "tWo" => 2, "thrEE" => 3 }
      after = { :One => 1, :tWo => 2, :thrEE => 3 }
      BigBlueButton::BigBlueButtonHash.symbolize_keys(before).should == after
    end

    it "works with multilevel hashes" do
      before = { "l1" => { "l2" => { "l3" => 1 } }, "l1b" => 2 }
      after = { :l1 => { :l2 => { :l3 => 1 } }, :l1b => 2 }
      BigBlueButton::BigBlueButtonHash.symbolize_keys(before).should == after
    end

    it "works with arrays" do
      before = { "a1" => [ "b1" => 1,  "b2" => 2 ], "b2" => 2 }
      after = { :a1 => [ :b1 => 1,  :b2 => 2 ], :b2 => 2 }
      BigBlueButton::BigBlueButtonHash.symbolize_keys(before).should == after
    end

    it "doesn't convert values" do
      before = { "a" => "a", "b" => "b" }
      after = { :a => "a", :b => "b" }
      BigBlueButton::BigBlueButtonHash.symbolize_keys(before).should == after
    end
  end

end
