require 'spec_helper'

describe CatalogController do
  describe "paths generated by custom routes:" do
    [
      :viewer,
      :details,
      :text,
      :guide,
    ].each do |action|
      it "maps {:controller => 'catalog', :action => '#{action}'} to /catalog/#{action}" do
        id = 'sample_collections_folder_level_1_1_1_1'
        route_for(:controller => 'catalog', 
                  :id => id,
                  :action => action.to_s).should == 
          {:path => "/catalog/#{id}/#{action}",
           :method => 'get'}
      end
    end
  end

  describe "parameters generated from routes:" do
    [
      :viewer,
      :details,
      :text,
      :guide,
    ].each do |action|
      it "maps /catalog/:id/#{action} to {:controller => 'catalog', :id => :id, :action => '#{action}'}" do
        id = 'sample_collections_folder_level_1_1_1_1'
        params_from(:get,
                    "/catalog/#{id}/#{action}").should ==
          {:controller => 'catalog',
           :id => id,
           :action => action.to_s}
      end
    end
  end

  [
    :viewer,
    :details,
    :text,
    :guide,
  ].each do |action|
    describe "#{action} action" do
      id = 'sample_collections_folder_level_1_1_1_1'

      it "gets document and response" do
        get action, :id => id
        assigns[:document].should_not be_nil
        assigns[:response].should_not be_nil
      end
    end
  end

  describe "guide action" do
    context "item with guide available" do
      id = 'sample_collections_folder_level_1_1_1_1'
  
      it "gets ead" do
        get :guide, :id => id
        assigns[:ead].should_not be_nil
      end

      it "sets guide heading" do
        get :guide, :id => id
        assigns[:document][Blacklight.config[:guide][:heading]].should_not be_nil
      end
    end

    context "item without guide available" do
      id = 'sample_books_1_1'

      it "sets format accordingly" do
        get :guide, :id => id
        assigns[:document]['format'].should == 'guide_not_available'
      end
    end
  end
  
  describe "text action" do
    has_text_id = 'sample_books_1_1'
    no_text_id = 'sample_collections_item_level_1_1_1'

    it "provides a short message if no text is found" do
      get :text, :id => has_text_id
      assigns[:document]['text_s'].should_not == 'Text not available.'
      get :text, :id => no_text_id
      assigns[:document]['text_s'].should == 'Text not available.'
    end
  end

  describe "details action" do
    ids = [
      'sample_books_1_1',
      'sample_books_1_2',
    ]

    it "assigns document_summary" do
      get :details, :id => ids[0]
      assigns[:document_summary].should_not be_nil
    end

    it "pulls the document for the first page" do
      ary = ids.collect { |id|
        get :details, :id => id
        assigns[:document_summary]
      }
      ary[0][:id].should == ary[1][:id]
    end
  end

  describe "random action" do
    it "assigns random_document" do
      get 'random'
      assigns[:random_document].should_not be_nil
      assigns[:random_document].class.should == SolrDocument
    end
  end
end
