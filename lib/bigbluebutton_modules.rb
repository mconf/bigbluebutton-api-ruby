require "base64"

module BigBlueButton

  # A class to store the modules configuration to be passed in BigBlueButtonApi#create_meeting().
  #
  # === Usage example:
  #
  #   modules = BigBlueButton::BigBlueButtonModules.new
  #
  #   # adds presentations by URL
  #   modules.add_presentation(:url, "http://www.samplepdf.com/sample.pdf")
  #   modules.add_presentation(:url, "http://www.samplepdf.com/sample2.pdf")
  #
  #   # adds presentations from a local file
  #   # the file will be opened and encoded in base64
  #   modules.add_presentation(:file, "presentations/class01.ppt")
  #
  #   # adds a base64 encoded presentation
  #   modules.add_presentation(:base64, "JVBERi0xLjQKJ....[clipped here]....0CiUlRU9GCg==", "first-class.pdf")
  #
  class BigBlueButtonModules

    attr_accessor :presentation_urls
    attr_accessor :presentation_files
    attr_accessor :presentation_base64s

    def initialize
      @presentation_urls = []
      @presentation_files = []
      @presentation_base64s = []
    end

    def add_presentation(type, value, name=nil)
      case type
      when :url
        @presentation_urls.push(value)
      when :file
        @presentation_files.push(value)
      when :base64
        @presentation_base64s.push([name, value])
      end
    end

    def to_xml
      unless has_presentations?
        ""
      else
        xml  = xml_header
        xml << presentations_to_xml
        xml << xml_footer
      end
    end

    private

    def has_presentations?
      !@presentation_urls.empty? or
        !@presentation_files.empty? or
        !@presentation_base64s.empty?
    end

    def xml_header
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?><modules>"
    end

    def xml_footer
      "</modules>"
    end

    def presentations_to_xml
      xml = "<module name=\"presentation\">"
      @presentation_urls.each { |url| xml << "<document url=\"#{url}\" />" }
      @presentation_base64s.each do |name, data|
        xml << "<document name=\"#{name}\">"
        xml << data
        xml << "</document>"
      end
      @presentation_files.each do |filename|
        xml << "<document name=\"#{File.basename(filename)}\">"
        File.open(filename, "r") do |file|
          xml << Base64.encode64(file.read)
        end
        xml << "</document>"
      end
      xml << "</module>"
    end

  end

end
