namespace :solr do
  desc 'delete all from solr'
  task :delete_solr => :environment do
    require 'pp'
    doc_ids = [
      "sample_video_history",
    ]
    doc_ids.each do |doc_id|
      puts doc_id
      pp Blacklight.solr.delete_by_id(doc_id)
    end
    pp Blacklight.solr.commit
  end

  def fetch_env_file
    f = ENV['FILE']
    raise "Invalid file. Set the location of the file by using the FILE argument." unless f and File.exists?(f)
    f
  end

  namespace :index do
    #ripped directly from Blacklight demo application
    desc "index a directory of json files"
    task :json_dir=>:environment do
      require 'pp'
      require 'nokogiri'
      require 'json'
      input_file = ENV['FILE']
      if File.directory?(input_file)
        Dir.new(input_file).each_with_index do |f,index|
          if File.file?(File.join(input_file, f))
            puts "indexing #{f}"
            ENV['FILE'] = File.join(input_file, f)

            json = IO.read(fetch_env_file)
            solr_pre = JSON.parse(json)
            solr_doc = Hash.new
            solr_pre.each do |key,value|
                solr_doc[key.to_sym] = value
            end
            require 'pp'
            pp solr_doc[:title_display]
            if !solr_doc[:title_display].blank?
                response = Blacklight.solr.add solr_doc
                pp response; puts
            end

          end
        end
        pp Blacklight.solr.commit
      end
    end

    # TODO Change this to index all the ua collection guides as well as manuscript
    # collections referred to within the db
    desc "Index a JSON file at FILE=<location-of-file>."
    task :json=>:environment do
      require 'nokogiri'
      require 'json'

      json = IO.read(fetch_env_file)
      solr_pre = JSON.parse(json)
      solr_doc = Hash.new
      solr_pre.each do |key,value|
        solr_doc[key.to_sym] = value
      end
      require 'pp'
      pp solr_doc[:title_display]
      if !solr_doc[:title_display].blank?
        response = Blacklight.solr.add solr_doc
        pp response; puts
      end
      pp Blacklight.solr.commit
    end
  end
end

