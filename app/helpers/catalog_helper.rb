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

  def fetch(urls)
    unless urls.respond_to?(:each)
      urls = [ urls ]
    end
    body = []
    urls.each do |url|
      response = Typhoeus::Request.get(url)
      body << response.body
    end
    body.join('')
  end

  def repo_logo_url(document)
    key = document['repository_display'].first
    if Blacklight.config[:repo_logo_url].has_key?(key)
      Blacklight.config[:repo_logo_url][key]
    else
      Blacklight.config[:repo_logo_url]['generic']
    end
  end

  def oh_url(document)
    if document.has_key?('synchronization_url_s')
      base = document['synchronization_url_s']
      args = []
      [
        :kw,
        :minute,
      ].each do |key|
        if params.has_key?(key)
          args << "#{key}=#{params[key]}"
        end
      end
      if args.length > 0
        url = [
          base,
          '&',
          args.join('&')
        ].join('')
      else
        url = base.first
      end
      URI.encode(url)
    end
  end
end
