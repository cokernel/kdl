require 'spec/spec_helper'

describe ApplicationHelper do
  include ApplicationHelper

  describe "#application_name" do
    it "is localized" do
      application_name.should == 'Kentucky Digital Library'
    end
  end

  describe "#document_guide_heading" do
    it "is the guide heading field when available" do
      @document = SolrDocument.new(Blacklight.config[:guide][:heading] => "A Fake Document")
      
      document_guide_heading.should == "A Fake Document"
    end

    it "falls back on the show heading field when the guide heading field is not available" do
      @document = SolrDocument.new(Blacklight.config[:show][:heading] => "A Fake Document")
      
      document_guide_heading.should == "A Fake Document"
    end

    it "falls back on the document id if no title is available" do
      @document = SolrDocument.new(:id => '123456')
      
      document_guide_heading.should == '123456'
    end
  end

  describe "#render_document_guide_heading" do
    it "wraps #document_guide_heading in an h1" do
      @document = SolrDocument.new(Blacklight.config[:guide][:heading] => "A Fake Document")

      render_document_guide_heading.should have_tag("h1", :text => document_guide_heading, :count => 1)
      render_document_guide_heading.html_safe?.should == true
    end
  end
end
