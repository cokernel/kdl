require 'spec/spec_helper'

module KDL
  class Parser
    def initialize(text)
      @xml = Nokogiri::XML(text)
      @xml.css('titleproper').each do |node|
        node.css('num').remove
      end
    end

    def title
      @xml.css('titleproper').first.text.strip
    end
  end
end
