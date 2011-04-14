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

  def fulltitle(did)
    [
      unitid(did),
      unittitle(did, :comma => :unitdate),
      unitdate(did),
    ].select { |item| !item.nil? }.join(' ')
  end

  def unitid(did)
    if did.unitid
      text = did.unitid.strip + ' '
      tagify(:unitid, text)
    end
  end

  def unittitle(did, options={})
    if did.unittitle
      text = trim_end_punctuation(did.unittitle)
      if options.has_key?(:comma)
        if did.send(options[:comma])
          text += ','
        end
      end
      text += ' '
      tagify(:unittitle, text)
    end
  end

  def unitdate(did)
    if did.unitdate
      text = trim_end_punctuation(did.unitdate) + ' '
      tagify(:unitdate, text)
    end
  end

  def tagify(field, representation)
    content_tag :span, representation, :class => field
  end

  def trim_end_punctuation(text)
    text.strip.sub(/[,.;:!?]*$/, '')
  end
end
