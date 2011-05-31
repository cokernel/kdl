require_dependency( 'vendor/plugins/blacklight/app/controllers/catalog_controller.rb')

class CatalogController < ApplicationController
  def about
  end

  def viewer
    @response, @document = get_solr_response_for_doc_id
    generate_pagination
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
    actual_id = params[:id]
    id = params[:id].sub(/_\d+$/, '_1')
    response, @document_summary = get_solr_response_for_doc_id id
    id = actual_id
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

  def generate_pagination
    unless @document.has_key?('unpaged_display')
      key = @document['parent_id_s']
      seq = @document['id'].sub(/^.*_(\d+)$/, "\\1").to_i #params[:seq]
      if @document['page_count_s'].nil?
          extra = {:per_page => 300}
      else
          extra = {:per_page => @document['page_count_s']}
      end
      @issue_response, @issue_documents = get_solr_response_for_field_values("parent_id_s",key, extra)
      @pages = @issue_response.docs.paginate :per_page => 1, :page => seq
      @current_page = @pages[seq - 1]
    end
  end
end
