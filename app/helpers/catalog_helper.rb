require_dependency('vendor/plugins/blacklight/app/helpers/catalog_helper.rb')
require_dependency('vendor/plugins/blacklight_ext_ead_simple/app/helpers/catalog_helper.rb')

module CatalogHelper
  def type_for(format, type)
    if Blacklight.config[:type_for].has_key?(format)
      types = Blacklight.config[:type_for][format]
      if types.respond_to? :join
        types.join('; ')
      else
        types
      end
    else
      type
    end
  end

  def eadsax(doc)
    if doc.has_key?('finding_aid_url_s')
      ead_url = doc['finding_aid_url_s'].first
      ead_xml = Typhoeus::Request.get(ead_url).body
      Eadsax::Ead.parse(ead_xml)
    end
  end

  def container_type(did, index)
    container_type = did.container_types[index]
    if container_type == 'othertype' or container_type.nil? or container_type == ''
      container_type = did.container_labels[index]
    end
    container_type
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

  def has_guide?(document)
    document.has_key?('finding_aid_url_s')
  end

  def has_text?(document)
    if document['text_s'].nil? or document.has_key?('synchronization_url_s')
      false
    else
      document['text_s'].length > 0
    end
  end

  def search_within_text(document)
    if has_guide?(document)
      'Search this collection'
    else
      'Search this item'
    end
  end

  def search_within(document)
    if has_guide?(document)
      ['source_s']
    else
      ['parent_id_s', 'format']
    end
  end

  def ead_id(element)
    text = element
    if element.respond_to?(:text)
      text = element.text
    end
    if text.respond_to?(:join)
      text = text[0]
    end
    Digest::MD5.hexdigest(text.to_s[0..19])
  end
  
  def ead_details(ead)
    hash = {
      :author => { :title => 'Author', :element => ead.eadheader.filedesc.titlestmt.author},
      :title => { :title => 'Title', :element => unittitle(ead.archdesc.did) },
      :date => { :title => 'Date', :element => unitdate(ead.archdesc.did) },
      :repository => { :title => 'Repository', :element => ead.archdesc.did.repository },
    }
    begin
      hash[:arrangement] = { :title => 'Arrangement', :element => ead.archdesc.arrangement.ps }
    rescue
    end

    begin
      hash[:location] = { :title => 'Location note', :element => ead.archdesc.did.physloc }
    rescue
    end

    begin
      hash[:conditions_access] = { :title => 'Conditions Governing Access note', :element => ead.archdesc.accessrestrict.ps }
    rescue
    end

    begin
      hash[:preferred_citation] = { :title => 'Preferred Citation Note', :element => ead.archdesc.prefercite.ps }
    rescue
    end

    begin
      hash[:extent] = { :title => 'Extent', :element => ead.archdesc.did.physdesc }
    rescue
    end

    begin
      hash[:creator] = { :title => 'Creator', :element => ead.archdesc.did.origination.famname }
    rescue
    end

    begin
      hash[:abstract] = { :title => 'Abstract', :element => ead.archdesc.did.abstracts }
    rescue
    end

    begin
      hash[:bioghist] = { :title => 'Biography/History', :element => ead.archdesc.bioghist, :handler => 'catalog/_show_partials/_ead/bioghist', :id_element => ead.archdesc.bioghist.ps }
    rescue
    end

    begin
      hash[:scopecontent] = { :title => 'Scope and Content', :element => ead.archdesc.scopecontent.ps }
    rescue
    end

    begin
      hash[:subjects] = { :title => 'Subjects', :element => ead.archdesc.controlaccess, :handler => 'catalog/_show_partials/_ead/controlaccess', :id_element => 'subjects' }
    rescue
    end

    begin
      hash[:descgrpestrict] = { :title => 'User Restrictions', :element => ead.archdesc.descgrpestrict, :handler => 'catalog/_show_partials/_ead/descgrpestrict', :id_element => ead.archdesc.descgrpestrict }
    rescue
      begin
        hash[:userestrict] = { :title => 'User Restrictions', :element => ead.archdesc.userestrict, :handler => 'catalog/_show_partials/_ead/userestrict', :id_element => ead.archdesc.userestrict }
      rescue
      end
    end

    begin
      hash[:accessrestrict] = { :title => 'Access Restrictions', :element => ead.archdesc.descgrp.accessrestrict }
    rescue
    end

    begin
      hash[:relatedmaterial] = { :title => 'Related Material', :element => ead.archdesc.descgrp.relatedmaterial, :handler => 'catalog/_show_partials/_ead/relatedmaterial', :id_element => ead.archdesc.descgrp.relatedmaterial }
    rescue
      begin
        hash[:relatedmaterial] = { :title => 'Related Material', :element => ead.archdesc.relatedmaterial, :handler => 'catalog/_show_partials/_ead/relatedmaterial', :id_element => ead.archdesc.relatedmaterial }
      rescue
      end
    end

    hash = hash.delete_if { |key, value|
      value[:element].to_s.length == 0
    }

    hash
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

  def repo_contact(document)
    key = document['repository_display'].first
    if Blacklight.config[:repo_contact].has_key?(key)
      Blacklight.config[:repo_contact][key]
    else
      nil
    end
  end

  def repo_url(document)
    contact = repo_contact(document)
    if contact and contact['url'] and contact['url'].length > 0
      contact['url']
    else
      nil
    end
  end

  def repo_abstract(document)
    contact = repo_contact(document)
    if contact and contact['abstract'] and contact['abstract'].length > 0
      contact['abstract']
    else
      nil
    end
  end

  def oh_url(document)
    if document.has_key?('synchronization_url_s')
      base = document['synchronization_url_s'].first
      unless base =~ /\.xml$/
        base += '.xml'
      end
      base.gsub!(/^http:/, 'https:')
      URI.encode(base)
    end
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or (!params[:search_field].blank? and params[:search_field] != 'all_fields') or params[:sort] =~ /random/
  end

  def alto_word_coordinates(document)
    key_candidates = [
      'coordinates_s',
      'coordinates_display',
    ]

    keys = key_candidates.select do |candidate|
      document.has_key? candidate
    end

    if keys.count > 0
      json = JSON.parse(document[keys[0]][0])
      if session[:search] and session[:search][:q]
        words = session[:search][:q].downcase.split(/\s+/)
        ret   = Array.new
        words.each do |word|
          if json[word]
            json[word].each do |bit|
              ret.push("  viewer.addRectangle([" + bit.join(', ') + "]);")
            end
          end
        end
        return ret.join("\n")
      else
        return ''
      end
    else
      return ''
    end
  end

  def full_screen
    session.has_key? :fs and session[:fs] == 1
  end

  def random_item
    Typhoeus::Request.get('http://eris.uky.edu/catalog/random').body
  end

  def json_get(url)
    JSON.parse Typhoeus::Request.get(url).body
  end

  def cal_info(url)
    h = json_get(url)
    d = h['date']
    {
      'cal_year' => d[0, 4],
      'cal_month' => d[5, 2],
    }
  end
end
