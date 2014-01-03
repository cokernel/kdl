require_dependency( 'vendor/plugins/blacklight/app/controllers/catalog_controller.rb')

class CatalogController < ApplicationController
  protect_from_forgery :except => :oai
  before_filter :downtime_notice

  include Blacklight::SolrHelper

  def downtime_notice
    finish = Time.parse("2013-12-28 23:59 EST")
    if Time.now < finish
      flash[:error] = "KDL will be down for scheduled maintenance on Saturday 2013-12-28.  We expect service to be restored by early evening.  We apologize for the inconvenience."
    end
  end

  def update
    search_session
    session[:search][:counter] = params[:counter]
    redirect_to :action => "show"
  end

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
    add_cal_info
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
    add_cal_info
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
    add_cal_info
  end

  def guide
    @response, @document = get_solr_response_for_doc_id
    add_cal_info
    if @document.has_key?('finding_aid_url_s')
      ead_url = @document['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      @ead = ead_xml
      @document[Blacklight.config[:guide][:heading]] = KDL::Parser.new(@ead).title
    else
      @document['format'] = 'guide_not_available'
    end
  end

  def index

    extra_head_content << '<link rel="alternate" type="application/rss+xml" title="RSS for results" href="'+ url_for(params.merge("format" => "rss")) + '">'
    extra_head_content << '<link rel="alternate" type="application/atom+xml" title="Atom for results" href="'+ url_for(params.merge("format" => "atom")) + '">'
    
    (@response, @document_list) = get_search_results
    add_cal_info
    @filters = params[:f] || []
    respond_to do |format|
      format.html { save_current_search_params }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
  end

  def repo_info
    @response, @document = get_solr_response_for_doc_id
  end

  def contact_us
    @response, @document = get_solr_response_for_doc_id
  end

  def submit_contact_request
    @response, @document = get_solr_response_for_doc_id
    if params[:name]
      key = @document['repository_display'].first
      if Blacklight.config[:repo_contact].has_key?(key)
        @repo = Blacklight.config[:repo_contact][key]
        unless @repo['email'].length > 0
          @repo['email'] = Blacklight.config[:repo_default_contact]
        end
        if @repo['email'].length > 0
          if params[:email]
            if params[:email].match(/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/)
              @patron = {
                'name' => params[:name],
                'email' => params[:email],
                'phone' => params[:phone],
                'question' => params[:question],
              }
              if verify_recaptcha
                email = CatalogMailer.deliver_contact_us(@repo, @document, @patron)
              else
                flash[:error] = 'There was an error submitting your request.'
              end
              redirect_to :back
            else
              flash[:error] = 'You must enter a valid email address.'
              redirect_to :back
            end
          else
            flash[:error] = 'You must enter an email address.'
            redirect_to :back
          end
        else
          flash[:error] = 'Repository has no contact email address.'
          redirect_to :back
        end
      end
    else
      flash[:error] = "You must enter your name."
      redirect_to :back
    end
  end

  def show
    @response, @document = get_solr_response_for_doc_id
    add_cal_info
    generate_pagination

    if @document.has_key?('finding_aid_url_s') and @document.has_key?('unpaged_display')
      redirect_to guide_catalog_path(@document['id'])
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

  def add_cal_info
    @calendar = {}
    if @document 
      if @document['format'] == 'newspapers' 
        @calendar['cal_title'] = @document['source_s'].first 
        if @document['full_date_s'] and @document['full_date_s'].first.strip =~ /^\d\d\d\d-\d\d-\d\d$/
          @calendar['cal_year'] = @document['full_date_s'].first.sub(/^(\d+)-\d+.*/, '\1')
          @calendar['cal_month'] = @document['full_date_s'].first.sub(/^\d+-(\d+).*/, '\1')
        end
        @calendar['url'] = 'http://kdl.kyvl.org/cal/first.php?title=' + CGI::escape(@calendar['cal_title'])
      end
    else
      if params.has_key?(:f) and params[:f].has_key?(:format) and params[:f][:format].include? "newspapers"
        @calendar['url'] = 'http://kdl.kyvl.org/cal/first.php'
        if params[:f].has_key?(:source_s)
          @calendar['cal_title'] = params[:f][:source_s].first
          @calendar['url'] += '?' + 'title=' + CGI::escape(@calendar['cal_title'])
        end
      end
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
          if thumbs.nil?
            thumbs = []
          end
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
    
    ### add paging to solr
    if extra_controller_params.has_key?(:sp) and extra_controller_params[:sp] == 'true'
      if solr_parameters.has_key?(:per_page)
        per_page = solr_parameters.delete(:per_page)
        solr_parameters[:rows] ||= per_page
      end
      solr_parameters[:rows] = params[:per_page] unless params[:per_page].blank?
      unless solr_parameters[:page].blank?
        if solr_parameters[:rows].blank?
          raise Exceptiobn.new("To use pagination when no :per_page is supplied in the URL, :rows must be configured in blacklight_config default_solr_params")
        end
        page = solr_parameters.delete(:page)
        #if extra_controller_params.has_key?(:sp) and extra_controller_params[:sp] == 'sp'
        #  page += 1
        #end
        solr_parameters[:start] = solr_parameters[:rows].to_i * page.to_i
        solr_parameters[:start] = 0 if solr_parameters[:start].to_i < 0
      end
      solr_parameters[:rows] = solr_parameters[:rows].to_i > self.max_per_page ? self.max_per_page.to_s : solr_parameters[:rows]
    else
      solr_parameters[:per_page] = solr_parameters[:per_page].to_i > self.max_per_page ? self.max_per_page.to_s : solr_parameters[:per_page]
    end
    Rails.logger.info(solr_parameters.to_json)


    ###
    # Sanity/requirements checks.
    ###

    # limit to MaxPerPage (100). Tests want this to be a string not an integer,
    # not sure why.
    #solr_parameters[:per_page] = solr_parameters[:per_page].to_i > self.max_per_page ? self.max_per_page.to_s : solr_parameters[:per_page]
    #solr_parameters[:rows] = solr_parameters[:rows].to_i > self.max_per_page ? self.max_per_page.to_s : solr_parameters[:rows]
    
    ###
    # Require title or relevance sort in some circumstances.
    ###
    if params[:q].blank?
      solr_parameters[:sort] = Blacklight.config[:sort_fields][3][1]
    else
      solr_parameters[:sort] = Blacklight.config[:sort_fields][0][1]
    end

    return solr_parameters
    
  end

  def solr_facet_params(facet_field, extra_controller_params={})
    input = params.deep_merge(extra_controller_params)

    # First start with a standard solr search params calculations,
    # for any search context in our request params. 
    solr_params = solr_search_params(extra_controller_params)
    
    # Now override with our specific things for fetching facet values
    solr_params[:"facet.field"] = facet_field

    # Need to set as f.facet_field.facet.limit to make sure we
    # override any field-specific default in the solr request handler. 
    solr_params[:"f.#{facet_field}.facet.limit"] = 
      if solr_params["facet.limit"] 
        solr_params["facet.limit"] + 1
      elsif respond_to?(:facet_list_limit)
        facet_list_limit.to_s.to_i + 1
      else
        20 + 1
      end
    solr_params['facet.offset'] = input[  Blacklight::Solr::FacetPaginator.request_keys[:offset]  ].to_i # will default to 0 if nil
    solr_params['facet.sort'] = input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ]     
    solr_params['facet.prefix'] = input[ Blacklight::Solr::FacetPaginator.request_keys[:prefix] ]
    solr_params[:rows] = 0

    return solr_params
  end

  def get_facet_pagination(facet_field, extra_controller_params={})
    solr_params = solr_facet_params(facet_field, extra_controller_params)
    
    # Make the solr call
    response = Blacklight.solr.find(solr_params)

    limit =       
      if respond_to?(:facet_list_limit)
        facet_list_limit.to_s.to_i
      elsif solr_params[:"f.#{facet_field}.facet.limit"]
        solr_params[:"f.#{facet_field}.facet.limit"] - 1
      else
        nil
      end

    args = {
      :offset => solr_params['facet.offset'], 
      :limit => limit,
      :sort => response["responseHeader"]["params"]["f.#{facet_field}.facet.sort"] || response["responseHeader"]["params"]["facet.sort"],
    }

    # Actually create the paginator!
    # NOTE: The sniffing of the proper sort from the solr response is not
    # currently tested for, tricky to figure out how to test, since the
    # default setup we test against doesn't use this feature. 
    return     Blacklight::Solr::FacetPaginator.new(response.facets.first.items, args)
  end
end
