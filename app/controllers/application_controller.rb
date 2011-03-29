require_dependency( 'vendor/plugins/blacklight/app/controllers/application_controller.rb')
# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  before_filter :add_remove_js_css

  private
  def add_remove_js_css
    javascript_includes.map{|js_links| js_links.delete("accordion") if js_links.include?({:plugin=>:blacklight})}
    stylesheet_links << ["application.css",{:media=>"all"}]
    javascript_includes << ["local.js", "my_accordion.js", "jquery-1.4.2.min.js" ]
  end
end
