require_dependency('vendor/plugins/blacklight/app/helpers/catalog_helper.rb')
require_dependency('vendor/plugins/blacklight_ext_ead_simple/app/helpers/catalog_helper.rb')

module Eadsax
  class Did
    element :dao, :value => :entityref, :as => :dao_link
  end
end

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

  def has_guide?(document)
    document.has_key?('finding_aid_url_s')
  end

  def has_text?(document)
    if document['text_s'].nil?
      false
    else
      document['text_s'].length > 0
    end
  end

  def ead_id(element)
    if element.identifier.nil?
      text = element
      if element.respond_to?(:text)
        text = element.text
      end
      if text.respond_to?(:join)
        text = text[0]
      end
      Digest::MD5.hexdigest(text.to_s[0..19])
    else
      element.identifier
    end
  end
  
  def ead_details(ead)
    hash = {
      :author => { :title => 'Author', :element => ead.eadheader.filedesc.titlestmt.author},
      :title => { :title => 'Title', :element => unittitle(ead.archdesc.did) },
      :date => { :title => 'Date', :element => unitdate(ead.archdesc.did) },
      :repository => { :title => 'Repository', :element => ead.archdesc.did.repository },
      :arrangement => { :title => 'Arrangement', :element => ead.archdesc.arrangement.ps },
      :conditions_access => { :title => 'Conditions Governing Access note', :element => ead.archdesc.accessrestrict.ps },
      :conditions_use => { :title => 'Conditions Governing Use note', :element => ead.archdesc.userestrict.ps },
      :preferred_citation => { :title => 'Preferred Citation Note', :element => ead.archdesc.prefercite.ps },
      :extent => { :title => 'Extent', :element => ead.archdesc.did.physdesc },
      :creator => { :title => 'Creator', :element => ead.archdesc.did.origination.famname },
      :abstract => { :title => 'Abstract', :element => ead.archdesc.did.abstracts },
      :bioghist => { :title => 'Biography/History', :element => ead.archdesc.bioghist, :handler => 'catalog/_show_partials/_ead/bioghist', :id_element => ead.archdesc.bioghist.ps },
      :scopecontent => { :title => 'Scope and Content', :element => ead.archdesc.scopecontent.ps },
      :subjects => { :title => 'Subjects', :element => ead.archdesc.controlaccess, :handler => 'catalog/_show_partials/_ead/controlaccess', :id_element => 'subjects' },
    }
    begin
      hash[:userestrict] = { :title => 'User Restrictions', :element => ead.archdesc.descgrp.userestrict }
    rescue
    end
    begin
      hash[:accessrestrict] = { :title => 'Access Restrictions', :element => ead.archdesc.descgrp.accessrestrict }
    rescue
    end
    begin
      hash[:relatedmaterial] = { :title => 'Related Material', :element => ead.archdesc.descgrp.relatedmaterial }
    rescue
    end
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

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or (!params[:search_field].blank? and params[:search_field] != 'all_fields')
  end

  def alto_word_coordinates(document)
    if document.has_key? 'coordinates_s'
      json = JSON.parse(document['coordinates_s'][0])
      if session[:search] and session[:search][:q]
        words = session[:search][:q].downcase.gsub(/\W/, '').split(/\s+/)
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
    end
  end
end
