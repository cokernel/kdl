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

  describe "#ead_id" do
    it "constructs a unique id for an EAD element" do
      element = double('Eadsax::Ead').as_null_object
      string = 'This is the text'
      expected = Digest::MD5.hexdigest(string)
      element.should_receive(:text).and_return(string)
      ead_id(element).should == expected
    end

    it "bases the unique id on up to the first 20 characters of the element text" do
      element = double('Eadsax::Ead').as_null_object
      string = 'This is a sample of what could be an incredibly long element'
      truncated = string[0..19]
      expected = Digest::MD5.hexdigest(truncated)
      element.should_receive(:text).and_return(string)
      ead_id(element).should == expected
    end

    it "can base the unique id on a submitted string" do
      string = 'This is a sample of what could be an incredibly long element'
      truncated = string[0..19]
      expected = Digest::MD5.hexdigest(truncated)
      ead_id(string).should == expected
    end

    it "can base the unique id on an array" do
      array = [
        'This is the first paragraph',
        'This is the second paragraph'
      ]
      expected = Digest::MD5.hexdigest(array[0][0..19])
      ead_id(array).should == expected
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
