require 'spec_helper'

describe CatalogController do
  describe "paths generated by custom routes:" do
    [
      'viewer',
      'details',
    ].each do |action|
      it "maps {:controller => 'catalog', :action => '#{action}'} to /catalog/#{action}" do
        route_for(:controller => 'catalog', 
                  :id => 'sample_aip_1',
                  :action => action).should == 
          {:path => "/catalog/sample_aip_1/#{action}",
           :method => 'get'}
      end
    end
  end

  describe "parameters generated from routes:" do
    [
      'viewer',
      'details',
    ].each do |action|
      it "maps /catalog/:id/#{action} to {:controller => 'catalog', :id => :id, :action => '#{action}'}" do
        params_from(:get,
                    "/catalog/sample_aip_1/#{action}").should ==
          {:controller => 'catalog',
           :id => 'sample_aip_1',
           :action => action}
      end
    end
  end

  [
    :viewer,
    :details,
  ].each do |action|
    describe "#{action} action" do
      doc_id = 'sample_aip_1'

      it "gets document and response" do
        get action, :id => doc_id
        assigns[:document].should_not be_nil
        assigns[:response].should_not be_nil
      end
    end
  end

  describe "details action" do
    ids = [
      'sample_aip_1',
      'sample_aip_2',
      'sample_aip_3',
    ]

    it "pulls the document for the first page" do
      ary = ids.collect { |id|
        get :details, :id => id
        assigns[:document]
      }
      ary[0][:id].should == ary[1][:id]
    end
  end
end
