require_dependency('vendor/plugins/blacklight/app/helpers/catalog_helper.rb')
require_dependency('vendor/plugins/blacklight_ext_ead_simple/app/helpers/catalog_helper.rb')
module CatalogHelper
  def eadsax(doc)
    if doc.has_key?('finding_aid_url_s')
      ead_url = doc['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      Eadsax::Ead.parse(ead_xml)
    end
  end
end

