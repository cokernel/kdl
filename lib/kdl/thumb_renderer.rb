require 'spec/spec_helper'

module KDL
  class ThumbRenderer < WillPaginate::LinkRenderer
    def prepare(collection, options, template)
      @collection = collection
      @options = options
      @template = template

      @images = []
      if @options.has_key?(:images) 
        @images = @options.delete(:images)
      end

      # reset values in case we're re-using this instance
      @total_pages = @param_name = @url_string = nil
    end

    def to_html
      links = @options[:page_links] ? windowed_links : []
      links = links.map {|link|
          link.sub!(/_\d+(\?.*)seq=(\d+)(.*)/, "_\\2\\1\\3")
          link.sub!(/_\d+(\/.*\?.*)seq=(\d+)(.*)/, "_\\2\\1\\3")
          link.sub!(/\?$/, '')
          link.sub!(/\/thumbs/, '/viewer')
          link
      }
  
      html = links.join(@options[:separator])
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end

  protected

    def windowed_links
      prev = nil

      visible_page_numbers.inject [] do |links, n|
        links << page_link_or_span(n, 'current_thumb')
        prev = n
        links
      end
    end

    def page_link_or_span(page, span_class, text = nil)
      text = "<img src=\"#{@images[page.to_i - 1]}\"/><p>#{page.to_i}</p>"
      text = text.html_safe if text.respond_to? :html_safe
      
      if page and page != current_page
        classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
        link_or_span = "<div class=\"picture left fixwidth\">" + page_link(page, text, :rel => rel_value(page), :class => classnames) + "</div>"
      else
        link_or_span = "<div class=\"current_thumb picture left fixwidth\">" + page_link(page, text, :rel => rel_value(page), :class => classnames) + "</div>"
      end
      link_or_span
    end
  end
end
