require 'spec/spec_helper'

describe CatalogHelper do
  include CatalogHelper

  let (:all_present) {{
    :unitid => "I. ",
    :unittitle => "Howdy, ",
    :unitdate => "1997 ",
  }}
  let (:missing_comma) {{
    :unitid => "I. ",
    :unittitle => "Howdy ",
    :unitdate => "1997 ",
  }}
  let (:punctuation_after_date) {{
    :unitid => "I. ",
    :unittitle => "Howdy ",
    :unitdate => "1997, ",
  }}

  describe "#fulltitle" do
    [
      :unitid,
      :unittitle,
      :unitdate,
    ].each do |field|
      it "contains the #{field} if available" do
        did = Eadsax::Did.parse(did_fragment(all_present))
        fulltitle(did).should have_tag("span.#{field}", :text => all_present[field].strip, :count => 1)
      end
    end

    [
      :unitid,
      :unittitle,
      :unitdate,
    ].each do |field|
      it "omits the #{field} if not available" do
        modified = all_present.reject {|k,v| k == field}
        did = Eadsax::Did.parse(did_fragment(modified))
        fulltitle(did).should_not have_tag("span.#{field}")
      end
    end

    it "includes a comma after unittitle if both it and unitdate appear" do
      did = Eadsax::Did.parse(did_fragment(missing_comma))
      fulltitle(did).should have_tag("span.unittitle", :text => "Howdy,", :count => 1)
    end

    it "does not include punctuation after unitdate" do
      did = Eadsax::Did.parse(did_fragment(punctuation_after_date))
      fulltitle(did).should have_tag("span.unitdate", :text => "1997", :count => 1)
    end
  end

  describe "#fetch" do
    it "fetches an external document" do
      url = 'http://projectblacklight.org'
      fetch(url).should =~ /What is Blacklight/m
    end
    
    it "gracefully handles arrays" do
      url = ['http://projectblacklight.org','http://rubyonrails.org']
      r = fetch(url)
      r.should =~ /What is Blacklight/m
      r.should =~ /Rails is released under the/m
    end
  end
end

def did_fragment(hash)
  units = [
    :unittitle,
    :unitdate,
    :unitid,
  ].collect do |unit|
    if hash.has_key? unit
      content_tag(unit, hash[unit])
    else
      ''
    end
  end.join('')
  content_tag(:did, units)
end
