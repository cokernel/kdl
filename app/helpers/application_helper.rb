require_dependency('vendor/plugins/blacklight/app/helpers/application_helper.rb')
module ApplicationHelper
  def application_name
    'Kentucky Digital Library'
  end

  def truncate(string, options = {})
    if not(options.has_key?(:length)) or string.length < options[:length]
      string
    elsif not(options.has_key?(:separator))
      string[0,options[:length]] + '...'
    else
      words = []
      len = 0
      string.split(options[:separator]).each do |word|
        break if len + word.length + options[:separator].length > options[:length]
        words << word
        len += word.length + options[:separator].length
      end
      words.join(options[:separator]) + ' ...'
    end
  end

  def render_document_index_label doc, opts
    label = nil
    label ||= doc.get(opts[:label]) if opts[:label].instance_of? Symbol
    label ||= opts[:label] if opts[:label].instance_of? String
    label ||= opts[:label].call(doc, opts) if opts[:label].instance_of? Proc
    label ||= doc.id
    truncate(label, :length => 110, :separator => ' ')
  end

  def render_thumbnail_url
    if @document.has_key? 'thumbnail_url_s' and @document['thumbnail_url_s'][0].length > 0
      @document['thumbnail_url_s'][0]
    else
      'http://kdl.kyvl.org/images/logo.png'
    end
  end

  def link_to_findingaid(doc, opts={:label=>Blacklight.config[:index][:show_link].to_sym, :counter => nil, :results_view => true})
    label = render_document_index_label doc, opts
    link_to_with_data(label, guide_url(doc), {:class => label.parameterize, :data => opts, :target => '_blank'})
  end

  def guide_url(document)
    id = document['id'].dup
    id.gsub!(/_.*/, '')
    "https://nyx.uky.edu/fa/findingaid/?id=#{id}"
  end

  def document_heading
    if @document.has_key? 'finding_aid_url_s' and @document.has_key? 'pub_date'
      heading = [
        @document[Blacklight.config[:show][:heading]],
        @document['pub_date'].first
      ].join(', ')
    else
      heading = @document[Blacklight.config[:show][:heading]]
    end
  end

  def document_guide_heading
    heading = @document[Blacklight.config[:guide][:heading]] || @document[Blacklight.config[:show][:heading]] || @document[:id]
  end

  def document_guide_subheading
    if @document.has_key? Blacklight.config[:guide][:heading] and @document[Blacklight.config[:guide][:heading]].respond_to?(:strip)
      'Part of ' + @document[Blacklight.config[:guide][:heading]]
    elsif @document.has_key? 'source_s'
      'Part of ' + @document['source_s'].first
    end
  end

  def render_document_guide_heading
    content_tag(:h1, document_guide_heading)
  end

  def render_document_heading
    if document_guide_subheading.nil?
      content_tag(:h1, document_heading)
    else
      content_tag(:h1, :class => 'guide_heading') do
        document_heading +
        content_tag(:h2, document_guide_subheading, :class => 'guide_subheading')
      end
    end
  end

  def render_format_link(format)
    if format == :everything
      if format_facet_clear?
        render_selected_search_by_everything
      else
        render_search_by_everything
      end
    else
      if facet_in_params?(:format, format.to_s.gsub(/_/, ' '))
        render_selected_search_by_format_value(format)
      else
        render_search_by_format_value(format)
      end
    end
  end

  def render_selected_search_by_everything(options ={})
    '<span class="format_select">' +
    render_search_by_everything(options) +
    '</span>'
  end

  def render_search_by_everything(options ={})
    link_to_unless(options[:suppress_link], 
                   'Everything',
                   clear_format_facet_and_redirect
    )
  end

  def render_selected_search_by_format_value(format, options ={})
    '<span class="format_select">' +
    render_search_by_format_value(format, options) +
    '</span>'
  end

  def render_search_by_format_value(format, options ={})
    link_to_unless(options[:suppress_link], 
                   format.to_s.gsub(/_/, ' ').capitalize,
                   switch_format_facet_and_redirect(
                     :format,
                     format.to_s.gsub(/_/, ' '))
    )
  end

  def clear_format_facet_and_redirect
    new_params = add_facet_params_and_redirect(:format, 'nope')
    new_params[:f][:format] = []
    new_params.delete(:sort)
    new_params.delete(:fq)
    new_params[:controller] = :catalog
    new_params
  end

  def switch_format_facet_and_redirect(field, value)
    new_params = add_facet_params_and_redirect(field, value)
    new_params[:f][:format] = []
    new_params[:f][:format].push(value)
    new_params[:controller] = :catalog
    new_params[:sort] = "sequence_sort asc, title_processed_s asc, pub_date_sort desc"
    new_params.delete(:fq)
    new_params
  end

  def format_facet_clear?
    if params[:f] and params[:f][:format]
      params[:f][:format].length == 0
    else
      true
    end
  end

  def switch_title_prefix_and_redirect(string)
    new_params = params.dup
    new_params[:fq] = "title_processed_s:#{string}*"
    new_params.delete(:page)
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key| 
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index. 
    new_params[:action] = "index"

    new_params[:controller] = :catalog
    new_params[:sort] = "sequence_sort asc, title_processed_s asc, pub_date_sort desc"
    new_params
  end

  def switch_creator_prefix_and_redirect(string)
    new_params = params.dup
    new_params[:fq] = "author_t:#{string}*"
    new_params.delete(:page)
    Blacklight::Solr::FacetPaginator.request_keys.values.each do |paginator_key| 
      new_params.delete(paginator_key)
    end
    new_params.delete(:id)

    # Force action to be index. 
    new_params[:action] = "index"

    new_params[:controller] = :catalog
    new_params[:sort] = "sequence_sort asc, title_processed_s asc, pub_date_sort desc"
    new_params
  end

  def render_search_title_by_prefix(string, options={})
    link_to_unless(options[:suppress_link], 
                   string,
                   switch_title_prefix_and_redirect(
                     string))
  end

  def render_search_creator_by_prefix(string, options={})
    link_to_unless(options[:suppress_link], 
                   string,
                   switch_creator_prefix_and_redirect(
                     string))
  end

  def top_sidebar_items
    @top_sidebar_items ||= []
  end
end
