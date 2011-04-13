require 'vendor/plugins/blacklight/app/helpers/application_helper.rb'
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def document_guide_heading
    "Cooper-Phillips family papers, 1839-1911, bulk 1857-1866"
  end

  def render_document_guide_heading
    '<h1>' + document_guide_heading + '</h1>'
  end
end
