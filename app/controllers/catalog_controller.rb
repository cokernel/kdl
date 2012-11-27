require_dependency( 'vendor/plugins/blacklight/app/controllers/catalog_controller.rb')

class CatalogController < ApplicationController

  include Blacklight::SolrHelper

  def max_per_page
    1500
  end

  def about
  end

  def random
    key = "random_#{rand(2**32)}"
    solr_response = Blacklight.solr.find( { :sort => "#{key} asc" })
    document_list = solr_response.docs.collect{|doc| SolrDocument.new(doc) }
    @random_document = document_list.shift
    until @random_document.has_key?('front_thumbnail_url_s')
      @random_document = document_list.shift
    end
    render :layout => false
  end

  def redirect_to_guide_or_first_page
    if @document.has_key?('digital_content_available_s') and @document['digital_content_available_s']
      ead_url = @document['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      @ead = Nokogiri::XML ead_xml
      if @ead.css('dao').first.nil?
        redirect_to guide_catalog_path(@document['id'])
      else
        first_page_id = @ead.css('dao').first['entityref']
        redirect_to viewer_catalog_path(first_page_id)
      end
    else
      redirect_to guide_catalog_path(@document['id'])
    end
  end

  def viewer
    @response, @document = get_solr_response_for_doc_id
    generate_pagination
    if @document.has_key?('finding_aid_url_s') and @document.has_key?('unpaged_display')
      redirect_to_guide_or_first_page
    end
    if @document.has_key?('finding_aid_url_s')
      ead_url = @document['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      @ead = ead_xml
      @document[Blacklight.config[:guide][:heading]] = KDL::Parser.new(@ead).title
    end
  end

  def thumbs
    viewer
  end

  def text 
    @response, @document = get_solr_response_for_doc_id
    begin
      text_to_check = @document['text_s'].first
    rescue
      text_to_check = @document['text_s']
    end
    unless text_to_check =~ /\S/
      @document['text_s'] = 'Text not available.'
    end
    generate_pagination
  end

  def details
    id = params[:id]
    response, @document_summary = get_solr_response_for_doc_id id
    @response, @document = get_solr_response_for_doc_id id
  end

  def guide
    @response, @document = get_solr_response_for_doc_id
    if @document.has_key?('finding_aid_url_s')
      ead_url = @document['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      @ead = ead_xml
      @document[Blacklight.config[:guide][:heading]] = KDL::Parser.new(@ead).title
    else
      @document['format'] = 'guide_not_available'
    end
  end

  def show
    @response, @document = get_solr_response_for_doc_id
    generate_pagination

    if @document.has_key?('finding_aid_url_s') and @document.has_key?('unpaged_display')
      redirect_to_guide_or_first_page
    end

    if @document.has_key?('finding_aid_url_s')
      ead_url = @document['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      @ead = ead_xml
      @document[Blacklight.config[:guide][:heading]] = KDL::Parser.new(@ead).title
    end

    respond_to do |format|
      format.html {setup_next_and_previous_documents}
      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons.
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name) }
      end
    end
  end

  def download
    @response, @document = get_solr_response_for_doc_id

    if @document.has_key?('reference_image_url_s')
      url = @document['reference_image_url_s'].first
      image = Typhoeus::Request.get(url).body
      send_data image,
                :filename => File.basename(url),
                :type => 'image/jpeg'
    end
  end

  def generate_pagination
    unless @document.has_key?('unpaged_display')
      key = @document['parent_id_s']
      seq = @document['id'].sub(/^.*_(\d+)$/, "\\1").to_i #params[:seq]
      limit = max_per_page
      if @document['page_count_s']
          limit = @document['page_count_s']
      end
      extra = { :per_page => limit }
      @issue_response, @issue_documents = get_solr_response_for_field_values("parent_id_s",key, extra)
      @pages = @issue_response.docs.paginate :per_page => 1, :page => seq
      @thumbs = @issue_response.docs.inject [] do |thumbs, page|
        if page.has_key? :thumbnail_url_s
          thumbs << page[:thumbnail_url_s].first
        end
      end
      @current_page = @pages[seq - 1]
    end
  end

  def solr_search_params(extra_controller_params={})
    solr_parameters = {}
    
  
    # Order of precedence for all the places solr params can come from,
    # start lowest, and keep over-riding with higher. 
    ####
    # Start with general defaults from BL config. Need to use custom
    # merge to dup values, to avoid later mutating the original by mistake.
    if Blacklight.config[:default_solr_params]
      Blacklight.config[:default_solr_params].each_pair do |key, value|
        solr_parameters[key] = case value
                                 when Hash then value.dup
                                 when Array then value.dup
                                 else value
                               end
      end
    end
    
    
    
    ###
    # Merge in search field configured values, if present, over-writing general
    # defaults
    ###
    search_field_def = Blacklight.search_field_def_for_key(params[:search_field] || extra_controller_params[:search_field])
    
    solr_parameters[:qt] = search_field_def[:qt] if search_field_def
    
    if ( search_field_def && search_field_def[:solr_parameters])
      solr_parameters.merge!( search_field_def[:solr_parameters])
    end

    
    ###
    # Merge in certain values from HTTP query itelf
    ###
    # Omit empty strings and nil values. 
    [:facets, :f, :page, :sort, :per_page].each do |key|
      solr_parameters[key] = params[key] unless params[key].blank?      
    end
    # :q is meaningful as an empty string, should be used unless nil!
    [:q].each do |key|
      solr_parameters[key] = params[key] if params[key]
    end
    # pass through any facet fields from request params["facet.field"] to
    # solr params. Used by Stanford for it's "faux hierarchical facets".
    if params.has_key?("facet.field")
      solr_parameters[:"facet.field"] ||= []
      solr_parameters[:"facet.field"].concat( [params["facet.field"]].flatten ).uniq!
    end
      
    ### pass through request for prefix
    if params.has_key?("fq")
      solr_parameters[:"fq"] ||= []
      solr_parameters[:"fq"].concat( [params["fq"]].flatten ).uniq!
    end

    
        
    # qt is handled different for legacy reasons; qt in HTTP param can not
    # over-ride qt from search_field_def defaults, it's only used if there
    # was no qt from search_field_def_defaults
    unless params[:qt].blank? || ( search_field_def && search_field_def[:qt])
      solr_parameters[:qt] = params[:qt]
    end
    
    ###
    # Merge in any values from extra_params argument. It doesn't seem like
    # we should have to take a slice of just certain keys, but legacy code
    # seems to put arguments in here that aren't really expected to turn
    # into solr params. 
    ###
    solr_parameters.deep_merge!(extra_controller_params.slice(:qt, :q, :facets,  :page, :per_page, :phrase_filters, :f, :fq, :fl, :qf, :df ).symbolize_keys   )





    
    ###
    # Defaults for otherwise blank values and normalization. 
    ###
    
    # TODO: Change calling code to expect this as a symbol instead of
    # a string, for consistency? :'spellcheck.q' is a symbol. Right now
    # callers assume a string. 
    solr_parameters["spellcheck.q"] = solr_parameters[:q] unless solr_parameters["spellcheck.q"]

    # And fix the 'facets' parameter to be the way the solr expects it.
    solr_parameters[:facets]= {:fields => solr_parameters[:facets]} if solr_parameters[:facets]
    
    # :fq, map from :f. 
    if ( solr_parameters[:f])
      f_request_params = solr_parameters.delete(:f)
      solr_parameters[:fq] ||= []
      f_request_params.each_pair do |facet_field, value_list|
        value_list.each do |value|
        solr_parameters[:fq] << "{!raw f=#{facet_field}}#{value}"
        end              
      end      
    end

    # Facet 'more' limits. Add +1 to any configured facets limits,
    facet_limit_hash.each_key do |field_name|
      next if field_name.nil? # skip the 'default' key
      next unless (limit = facet_limit_for(field_name))

      solr_parameters[:"f.#{field_name}.facet.limit"] = (limit + 1)
    end

    ##
    # Merge in search-field-specified LocalParams into q param in
    # solr LocalParams syntax
    ##
    if (search_field_def && hash = search_field_def[:solr_local_parameters])
      local_params = hash.collect do |key, val|
        key.to_s + "=" + solr_param_quote(val, :quote => "'")
      end.join(" ")
      solr_parameters[:q] = "{!#{local_params}} #{solr_parameters[:q]}"
    end
    
    
    ###
    # Sanity/requirements checks.
    ###
    
    # limit to MaxPerPage (100). Tests want this to be a string not an integer,
    # not sure why. 
    solr_parameters[:per_page] = solr_parameters[:per_page].to_i > self.max_per_page ? self.max_per_page.to_s : solr_parameters[:per_page]

    ###
    # Require title or relevance sort in some circumstances.
    ###
    if params[:q].blank?
      solr_parameters[:sort] = Blacklight.config[:sort_fields][3][1]
    else
      solr_parameters[:sort] = Blacklight.config[:sort_fields][0][1]
    end

    ### Require University of Kentucky.
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "{!raw f=repository_facet}University of Kentucky"
    solr_parameters[:fq] << "(format:newspapers AND title_t:'Kentucky' AND title_t:'kernel') OR (*:* NOT(format:newspapers))"

    return solr_parameters
    
  end
end
