require 'net/http_multipart_post'
require 'facebooker/rails/controller'
require 'facebooker/rails/facebook_url_rewriting'
require 'facebooker/rails/facebook_session_handling'
require 'facebooker/rails/facebook_asset_path'
require 'facebooker/rails/facebook_request_fix'
require 'facebooker/rails/routing'

module ::ActionController
  class Base
    def self.inherited_with_facebooker(subclass)
      inherited_without_facebooker(subclass)
      if subclass.to_s == "ApplicationController"
        subclass.send(:include,Facebooker::Rails::Controller) 
        subclass.helper Facebooker::Rails::Helpers
      end
    end
    class << self
      alias_method_chain :inherited, :facebooker
    end
  end
end


class ActionController::Routing::Route
  def recognition_conditions_with_facebooker
    defaults = recognition_conditions_without_facebooker 
    defaults << " env[:canvas] == conditions[:canvas] " if conditions[:canvas]
    defaults
  end
  alias_method_chain :recognition_conditions, :facebooker
end
# We turn off route optimization to make named routes use our code for figuring out if they should go to the session
ActionController::Base::optimise_named_routes = false
# pull :canvas=> into env in routing to allow for conditions
ActionController::Routing::RouteSet.send :include,  Facebooker::Rails::Routing::RouteSetExtensions
ActionController::Routing::RouteSet::Mapper.send :include, Facebooker::Rails::Routing::MapperExtensions

facebook_config = File.dirname(__FILE__) + '/../../../config/facebooker.yml'

if File.exists?(facebook_config)
  FACEBOOKER = YAML.load_file(facebook_config)[RAILS_ENV] 
  ENV['FACEBOOKER_RELATIVE_URL_ROOT'] = FACEBOOKER['canvas_page_name']
  ENV['FACEBOOK_API_KEY'] = FACEBOOKER['api_key']
  ENV['FACEBOOK_SECRET_KEY'] = FACEBOOKER['secret_key']
else
  puts "Facebook configuration not loaded. Run rake facebooker:setup or ignore if this is a test."
end