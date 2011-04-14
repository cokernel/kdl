require 'spec/spec_helper'

describe CatalogHelper do
  include CatalogHelper

  describe "#unitid" do
    it "returns the unitid wrapped in a span" do
      fragment = '<did><unittitle>Howdy,<unittitle><unitid>I.</unitid><unitdate>1997</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unitid(did).should have_tag("span.unitid", :text => 'I.', :count => 1)
      unitid(did).html_safe?.should == true
    end

    it "is blank if the did does not have a unitid" do
      fragment = '<did><unittitle>Howdy,<unittitle><unitdate>1997</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unitid(did).should == ''
    end
  end

  describe "#unittitle" do
    it "returns the unittitle wrapped in a span" do
      fragment = '<did><unittitle>Howdy,</unittitle><unitid>I.</unitid><unitdate>1997</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unittitle(did).should have_tag("span.unittitle", :text => 'Howdy,', :count => 1)
      unittitle(did).html_safe?.should == true
    end

    it "ends in a comma if there is a unitdate" do
      fragment = '<did><unittitle>Howdy!</unittitle><unitdate>4096</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unittitle(did).should have_tag("span.unittitle", :text => 'Howdy,', :count => 1)
      unittitle(did).html_safe?.should == true
    end

    it "does not end in punctuation if there is no unitdate" do
      fragment = '<did><unittitle>Howdy,</unittitle><unitid>I.</unitid></did>'
      did = Eadsax::Did.parse(fragment)
      unittitle(did).should have_tag("span.unittitle", :text => 'Howdy', :count => 1)
      unittitle(did).html_safe?.should == true
    end

    it "is blank if the did does not have a unittitle" do
      fragment = '<did><unitid>I.</unitid><unitdate>1997</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unittitle(did).should == ''
    end
  end

  describe "#unitdate" do
    it "returns the unitdate wrapped in a span" do
      fragment = '<did><unittitle>Howdy,</unittitle><unitid>I.</unitid><unitdate>1997</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unitdate(did).should have_tag("span.unitdate", :text => '1997', :count => 1)
      unitdate(did).html_safe?.should == true
    end

    it "does not end in punctuation" do
      fragment = '<did><unittitle>Howdy,</unittitle><unitid>I.</unitid><unitdate>1997.</unitdate></did>'
      did = Eadsax::Did.parse(fragment)
      unitdate(did).should have_tag("span.unitdate", :text => '1997', :count => 1)
      unitdate(did).html_safe?.should == true
    end

    it "is blank if the did does not have a unitdate" do
      fragment = '<did><unitid>I.</unitid><unittitle>Howdy,</unittitle></did>'
      did = Eadsax::Did.parse(fragment)
      unitdate(did).should == ''
    end
  end
end
