require_dependency( 'vendor/plugins/blacklight/app/controllers/catalog_controller.rb')

class CatalogController < ApplicationController
  def viewer
    @response, @document = get_solr_response_for_doc_id
  end
end
