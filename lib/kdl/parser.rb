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
      if @xml.css('unittitle').length > 0
        if @xml.css('unitdate').length > 0
          if @xml.css('unittitle unitdate').length > 0
            @xml.css('unittitle').first.text.strip
          else
            [
              @xml.css('unittitle').first.text.strip,
              @xml.css('unitdate').first.text.strip
            ].join(', ').gsub(/,\s*,/, ',')
          end
        else
          @xml.css('unittitle').first.text.strip
        end
      else
        @xml.css('titleproper').first.text.strip
      end
    end
  end
end
