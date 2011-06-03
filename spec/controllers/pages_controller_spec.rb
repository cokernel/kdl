require 'spec_helper'

describe PagesController do

  #Delete these examples and add some real ones
  it "should use PagesController" do
    controller.should be_an_instance_of(PagesController)
  end

  [
    :about,
    :partners,
    :recent_changes,
  ].each do |page|
    describe "GET '#{page}'" do
      it "should be successful" do
        get page
        response.should be_success
      end
    end
  end
end
