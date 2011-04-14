require 'vendor/plugins/blacklight/app/helpers/application_helper.rb'
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def document_guide_heading
    @document[Blacklight.config[:guide][:heading]] || @document[Blacklight.config[:show][:heading]] || @document[:id]
  end

  def render_document_guide_heading
    content_tag(:h1, document_guide_heading)
  end
end
