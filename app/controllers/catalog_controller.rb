require_dependency( 'vendor/plugins/blacklight/app/controllers/catalog_controller.rb')

class CatalogController < ApplicationController
  def viewer
    @response, @document = get_solr_response_for_doc_id
    generate_pagination
  end

  def details
    @response, @document = get_solr_response_for_doc_id
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
