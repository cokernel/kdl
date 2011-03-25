require 'spec_helper'

describe CatalogController do
  describe "paths generated by custom routes:" do
    it "should map {:controller => 'catalog', :action => 'viewer'} to /catalog/viewer" do
      route_for(:controller => 'catalog', 
                :id => 'sample_aip_1',
                :action => 'viewer').should == 
        {:path => '/catalog/sample_aip_1/viewer',
         :method => 'get'}
    end
  end
end