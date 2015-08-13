# You can configure Blacklight from here. 
#   
#   Blacklight.configure(:environment) do |config| end
#   
# :shared (or leave it blank) is used by all environments. 
# You can override a shared key by using that key in a particular
# environment's configuration.
# 
# If you have no configuration beyond :shared for an environment, you
# do not need to call configure() for that envirnoment.
# 
# For specific environments:
# 
#   Blacklight.configure(:test) {}
#   Blacklight.configure(:development) {}
#   Blacklight.configure(:production) {}
# 

Blacklight.configure(:shared) do |config|

  # Set up and register the default SolrDocument Marc extension
  SolrDocument.extension_parameters[:marc_source_field] = :marc_display
  SolrDocument.extension_parameters[:marc_format_type] = :marc21
  SolrDocument.use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  SolrDocument.use_extension( Blacklight::Solr::Document::DublinCore)
    
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  SolrDocument.field_semantics.merge!(    
    :title => "title_display",
    :author => "author_display",
    :creator => "author_display",
    :contributor => "contributor_s",
    :publisher => "repository_display",
    :date => "pub_date", #"full_date_s",
    :format => "format",
    :type => "type_display",
    :coverage => "coverage_s",
    :source => "source_s",
    :rights => "usage_display",
    :description => "description_display",
    :subject => "subject_topic_facet",
    :identifier => "id",
    :language => "language_display",
    :reference_audio => "reference_audio_url_s",
    :relation => "reference_image_url_s"
  )
  #SolrDocument.field_semantics.merge!(    
  #  :title => "title_display",
  #  :author => "author_display",
  #  :language => "language_facet"  
  #)
        
  
  ##############################

  config[:default_solr_params] = {
    :qt => "search",
    :per_page => 10 
  }
  
  
  config[:guide] = {
    :heading => "title_guide_display",
  }

  # solr field values given special treatment in the show (single result) view
  config[:show] = {
    :html_title => "title_display",
    :heading => "title_display",
    :display_type => "format"
  }

  # solr fld values given special treatment in the index (search results) view
  config[:index] = {
    :show_link => "title_display",
    :record_display_type => "format"
  }

  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  # TODO: Reorganize facet data structures supplied in config to make simpler
  # for human reading/writing, kind of like search_fields. Eg,
  # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
  config[:facet] = {
    :field_names => (facet_fields = [
      "format",
      #"repository_facet",
      "source_s",
      "pub_date",
      #"coverage_s",
      #"subject_topic_facet",
      #"language_facet",
      #"lc_1letter_facet",
      #"subject_geo_facet",
      #"subject_era_facet",
    ]),
    :labels => {
      "format"              => "Format",
      "pub_date"            => "Publication Year",
      "subject_topic_facet" => "Topic",
      "language_facet"      => "Language",
      "lc_1letter_facet"    => "Call Number",
      "subject_era_facet"   => "Era",
      "subject_geo_facet"   => "Region",
      "repository_facet"    => "Repository",
      "source_s"            => "Collection",
      "coverage_s"          => "Coverage",
    },
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.     
    :limits => {
      "format" => 20,
      "subject_facet" => 20,
      "language_facet" => true,
      "repository_facet" => 10,
      "source_s" => 10,
      "pub_date" => 10,
    }
  }

  config[:facet][:range] ||= {}
  config[:facet][:range]["pub_date"] = true

  # Have BL send all facet field names to Solr, which has been the default
  # previously. Simply remove these lines if you'd rather use Solr request
  # handler defaults, or have no facets.
  config[:default_solr_params] ||= {}
  config[:default_solr_params][:"facet.field"] = facet_fields

  # solr fields to be displayed in the index (search results) view
  #   The ordering of the field names is the order of the display 
  config[:index_fields] = {
    :field_names => [
      "source_s",
      "pub_date",
      "format",
      "language_facet",
      "published_display",
      "published_vern_display",
      "lc_callnum_display"
    ],
    :labels => {
      "title_display"           => "Title:",
      "title_vern_display"      => "Title:",
      "source_s"                => "Collection:",
      "pub_date"                => "Publication date",
      "format"                  => "Format:",
      "language_facet"          => "Language:",
      "published_display"       => "Published:",
      "published_vern_display"  => "Published:",
      "lc_callnum_display"      => "Call number:"
    }
  }

  # solr fields to be displayed in the show (single result) view
  #   The ordering of the field names is the order of the display 
  config[:show_fields] = {
    :field_names => [
      "title_display",
      "title_vern_display",
      "subtitle_display",
      "subtitle_vern_display",
      "author_display",
      "author_vern_display",
      "format",
      "url_fulltext_display",
      "url_suppl_display",
      "material_type_display",
      "language_facet",
      "published_display",
      "published_vern_display",
      "lc_callnum_display",
      "isbn_t",
      "pub_date",
      "date_digitized_display",
      "description_display",
      "language_display",
      "relation_display",
      "publisher_display",
      "repository_display",
      "contributor_s",
      #"type_display",
      "subject_topic_facet",
    ],
    :labels => {
      #"type_display"            => "Type:",
      "subject_topic_facet"     => "Subject:",
      "repository_display"      => "Repository:",
      "publisher_display"       => "Publisher:",
      "relation_display"        => "Relation:",
      "language_display"        => "Language:",
      "description_display"     => "Description:",
      "date_digitized_display"  => "Date uploaded:",
      "pub_date"                => "Publication date:",
      "title_display"           => "Title:",
      "title_vern_display"      => "Title:",
      "subtitle_display"        => "Subtitle:",
      "subtitle_vern_display"   => "Subtitle:",
      "author_display"          => "Creator:",
      "author_vern_display"     => "Creator:",
      "format"                  => "Format:",
      "url_fulltext_display"    => "URL:",
      "url_suppl_display"       => "More Information:",
      "material_type_display"   => "Physical description:",
      "language_facet"          => "Language:",
      "published_display"       => "Published:",
      "published_vern_display"  => "Published:",
      "lc_callnum_display"      => "Call number:",
      "isbn_t"                  => "ISBN:",
      "contributor_s"           => "Contributor:",
    }
  }


  # "fielded" search configuration. Used by pulldown among other places.
  # For supported keys in hash, see rdoc for Blacklight::SearchFields
  #
  # Search fields will inherit the :qt solr request handler from
  # config[:default_solr_parameters], OR can specify a different one
  # with a :qt key/value. Below examples inherit, except for subject
  # that specifies the same :qt as default for our own internal
  # testing purposes.
  #
  # The :key is what will be used to identify this BL search field internally,
  # as well as in URLs -- so changing it after deployment may break bookmarked
  # urls.  A display label will be automatically calculated from the :key,
  # or can be specified manually to be different. 
  config[:search_fields] ||= []

  # This one uses all the defaults set by the solr request handler. Which
  # solr request handler? The one set in config[:default_solr_parameters][:qt],
  # since we aren't specifying it otherwise. 
  config[:search_fields] << {
    :key => "all_fields",  
    :display_label => 'All Fields'   
  }

  # Now we see how to over-ride Solr request handler defaults, in this
  # case for a BL "search field", which is really a dismax aggregate
  # of Solr search fields. 
  config[:search_fields] << {
    :key => 'title',     
    # solr_parameters hash are sent to Solr as ordinary url query params. 
    :solr_parameters => {
      :"spellcheck.dictionary" => "title"
    },
    # :solr_local_parameters will be sent using Solr LocalParams
    # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    # Solr parameter de-referencing like $title_qf.
    # See: http://wiki.apache.org/solr/LocalParams
    :solr_local_parameters => {
      :qf => "$title_qf",
      :pf => "$title_pf"
    }
  }
  config[:search_fields] << {
    :key =>'author',     
    :solr_parameters => {
      :"spellcheck.dictionary" => "author" 
    },
    :solr_local_parameters => {
      :qf => "$author_qf",
      :pf => "$author_pf"
    }
  }

  # Specifying a :qt only to show it's possible, and so our internal automated
  # tests can test it. In this case it's the same as 
  # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
  config[:search_fields] << {
    :key => 'subject', 
    :qt=> 'search',
    :solr_parameters => {
      :"spellcheck.dictionary" => "subject"
    },
    :solr_local_parameters => {
      :qf => "$subject_qf",
      :pf => "$subject_pf"
    }
  }

  #config[:search_fields] << {
  #  :key => 'full_date_s',
  #  :display_label => 'Exact Date',
  #}
  
  # "sort results by" select (pulldown)
  # label in pulldown is followed by the name of the SOLR field to sort by and
  # whether the sort is ascending or descending (it must be asc or desc
  # except in the relevancy case).
  # label is key, solr field is value
  config[:sort_fields] ||= []
  config[:sort_fields] << ['relevance', 'score desc, pub_date_sort desc, title_sort asc, sequence_sort asc']
  config[:sort_fields] << ['year', 'pub_date_sort desc, title_sort asc']
  config[:sort_fields] << ['author', 'author_sort asc, title_sort asc']
  config[:sort_fields] << ['title', 'sequence_sort asc, title_processed_s asc, pub_date_sort desc']
  
  # If there are more than this many search results, no spelling ("did you 
  # mean") suggestion is offered.
  config[:spell_max] = 5

  # Repository logos
  config[:repo_logo_url] = {
    'generic' => '/images/repos/logo_placeholder.png',
    'Appalshop Inc.' => '/images/repos/kap_logo.png',
    'Lexington Public Library' => '/images/repos/kyl_logo.png',
    'Morehead State University' => '/images/repos/kmm_logo.png',
    'University of Kentucky' => '/images/repos/kuk_logo.png',
  }

  config[:repo_default_contact] = 'DLS-L@LSV.UKY.EDU'
  config[:repo_contact] = {
    'Appalshop Inc.' => {
      'bucket' => [
        'Appalshop Inc.',
      ],
      'phone' => '',
      'email' => '',
    },
    'Asbury College' => {
      'bucket' => [
        'Asbury College',
      ],
      'phone' => '',
      'email' => '',
    },
    'Berea College' => {
      'bucket' => [
        'Berea College',
      ],
      'phone' => '',
      'email' => '',
    },
    'Centre College' => {
      'bucket' => [
        'Centre College',
        'Special Collections',
      ],
      'phone' => '(859) 238-5274',
      'email' => 'bob.glass@centre.edu',
    },
    'Eastern Kentucky University' => {
      'bucket' => [
        'Eastern Kentucky University',
        'University Archives',
      ],
      'phone' => '(859) 622-1792',
      'email' => 'archives.library@eku.edu',
    },
    'Georgetown College' => {
      'bucket' => [
        'Georgetown College',
      ],
      'phone' => '',
      'email' => '',
    },
    'Keeneland Racing Association' => {
      'bucket' => [
        'Keeneland Racing Association',
        'Library',
      ],
      'phone' => '(859) 280-4761',
      'email' => 'bryder@keeneland.com',
    },
    'Kentucky Department for Libraries and Archives' => {
      'bucket' => [
        'Kentucky Department for Libraries and Archives',
      ],
      'phone' => '',
      'email' => '',
    },
    'Kentucky Historical Society' => {
      'bucket' => [
        'Kentucky Historical Society',
        '100 W. Broadway',
        'Frankfort, KY 40601'
      ],
      'phone' => '(502) 564-1792',
      'email' => 'jennifer.duplaga@ky.gov',
      'url' => 'http://history.ky.gov/',
      'abstract' => "The Kentucky Historical Society engages people in the exploration of the commonwealth's diverse heritage. Through comprehensive and innovative services, interpretive programs and stewardship, we provide connections to the past, perspective on the present and inspiration for the future. KHS collects, preserves, conserves, interprets and shares information, memories and materials from Kentucky's past to assist those interested in exploring and preserving that heritage.",
    },
    'Kentucky State Universty' => {
      'bucket' => [
        'Kentucky State Universty',
      ],
      'phone' => '',
      'email' => '',
    },
    'Lexington Public Library' => {
      'bucket' => [
        'Lexington Public Library',
        'The Kentucky Room',
      ],
      'phone' => '(859) 231-5523',
      'email' => 'icornett@lexpublib.org',
    },
    'Louisville Free Public Library' => {
      'bucket' => [
        'Louisville Free Public Library',
      ],
      'phone' => '',
      'email' => '',
    },
    'Morehead State University' => {
      'bucket' => [
        'Morehead State University',
        'Special Collections Department',
      ],
      'phone' => '(606) 783-2829',
      'email' => 'dj.baker@moreheadstate.edu',
    },
    'Northern Kentucky University' => {
      'bucket' => [
        'Northern Kentucky University',
      ],
      'phone' => '',
      'email' => '',
    },
    'The Filson Historical Society' => {
      'bucket' => [
        'The Filson Historical Society',
        '1310 South Third Street',
        'Louisville, KY 40208',
      ],
      'phone' => '(502) 635-5083',
      'email' => 'research@filsonhistorical.org',
      'url' => 'http://www.filsonhistorical.org/',
      'abstract' => "Since our founding in 1884, The Filson Historical Society’s mission has been to collect, preserve, and tell the significant stories of Kentucky and Ohio Valley history and culture. The Filson performs its mission by collecting and securing historical and cultural documents, books, objects, and art, exhibiting and interpreting our collections for the public, supporting research and study, and presenting educational programs 
      and events.",
    },
    'Transylvania University' => {
      'bucket' => [
        'Transylvania University',
        'Special Collections and Archives',
      ],
      'phone' => '859-246-5002', #'(859) 233-8225', # '859-246-5002',
      'email' => 'bjgooch@transy.edu',
      'url' => 'http://www.transy.edu/academics/library/collections.htm',
      'abstract' => "Special Collections and Archives at Transylvania University provides secure housing and specialized care for the unique and valuable research materials of the library. The department contains rare books, pamphlets, photographs, manuscripts, and the University Archives. Notable collections include the J. Winston Coleman, Jr. Kentuckiana Collection, the Clara Peck Natural History Collection. which includes Audubons's BIRDS OF AMERICA, over 5,000 volumes of books from the old Medical Library and over 1,800 handwritten medical theses. These collections provide a unique opportunity for students to use primary source materials and to study Kentucky history and the important books of Western culture. The department is located on the upper level of the library and is open to researchers by appointment Monday - Friday from 1:00 - 4:30 p.m.",
    },
    'University of Kentucky' => {
      'bucket' => [
        'University of Kentucky',
        'Special Collections Library',
      ],
      'phone' => '(859) 257-8611',
      'email' => 'EXPLOREUK-REF@LSV.UKY.EDU', #'SCLREF@LSV.UKY.EDU',
      'url' => 'http://libraries.uky.edu/lib.php?lib_id=13',
      'abstract' => "Special Collections is home to UK Libraries' collection of rare books, Kentuckiana, the Archives, the Louie B. Nunn Center for Oral History, the King Library Press, and the Wendell H. Ford Public Policy Research Center. The mission of Special Collections is to locate and preserve materials documenting the social, cultural, economic, and political history of the Commonwealth of Kentucky. Materials are acquired regardless of format and include both primary and secondary sources; Kentuckiana is collected comprehensively. Special Collections maintains a records management program for all records generated by the University and serves as its archival repository for permanent records. As part of the mission, Special Collections advances and supports the research, teaching, and scholarship of the University and beyond by preserving and providing access to its holdings.",
    },
    'University of Lousville' => {
      'bucket' => [
        'University of Lousville',
        'Special Collections: Photographic Archives and Rare Books ',
      ],
      'phone' => '(502) 852-6752',
      'email' => 'Special.Collections@louisville.edu',
    },
    'Western Kentucky University' => {
      'bucket' => [
        'Western Kentucky University',
      ],
      'phone' => '',
      'email' => '',
    },
  }
  
  config[:ead_fields] = [
    :author,
    :title,
    :date,
    :repository,
    :arrangement,
    :location,
    :conditions_access,
    :conditions_use,
    :preferred_citation,
    :extent,
    :creator,
    :abstract,
    :bioghist,
    :scopecontent,
    :subjects,
    :userestrict,
    :accessrestrict,
    :relatedmaterial,
  ]

  config[:oai] = {
    :provider => {
      :repository_name => 'ExploreUK',
      :repository_url => 'http://exploreuk.uky.edu/catalog/oai',
      :record_prefix => 'exploreuk.uky.edu',
      :admin_email => 'm.slone@uky.edu'
    },
    :document => {
      :timestamp_field => 'timestamp'
    }
  }

  config[:type_for] = {
    'archival_material' => 'collection',
    'collections' => 'collection',
    'images' => 'image',
    'maps' => 'image',
    'oral histories' => 'sound',
    'books' => 'text',
    'newspapers' => 'text',
    'minutes' => 'text',
    'journals' => 'text',
    'theses' => 'text',
    'course catalogs' => 'text',
    'athletic publications' => 'text',
    'directories' => 'text',
    'ledgers' => 'text',
    'yearbooks' => ['text', 'image'],
  }
end

