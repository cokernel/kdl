require 'spec/spec_helper'

module KDL
  class LinkRenderer < WillPaginate::LinkRenderer
    def to_html
      links = @options[:page_links] ? windowed_links : []
      # previous/next buttons
      links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])
      links.push page_link_or_span(@collection.next_page, 'disabled next_page', @options[:next_label])
  
      links = links.map {|link|
          link.sub!(/_\d+(\?.*)seq=(\d+)(.*)/, "_\\2\\1\\3")
          link.sub!(/_\d+(\/.*\?.*)seq=(\d+)(.*)/, "_\\2\\1\\3")
          link.sub!(/\?$/, '')
          link
      }
  
      html = links.join(@options[:separator])
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end
  end
end
