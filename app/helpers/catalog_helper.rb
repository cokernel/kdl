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

  def unitid(did)
    if did.unitid
      content_tag(:span, did.unitid, :class => :unitid)
    else
      ''
    end
  end

  def unittitle(did)
    if did.unittitle
      text = trim_end_punctuation(did.unittitle)
      if did.unitdate
        text += ','
      end
      content_tag(:span, text, :class => :unittitle)
    else
      ''
    end
  end

  def unitdate(did)
    if did.unitdate
      text = trim_end_punctuation(did.unitdate)
      content_tag(:span, text, :class => :unitdate)
    else
      ''
    end
  end

  def trim_end_punctuation(text)
    text.sub(/[,.;:!?]*$/, '')
  end
end
