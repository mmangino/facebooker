# Added support to the Facebooker.yml file for switching to the new profile design..
# Config parsing needs to happen before files are required.
facebook_config = "#{RAILS_ROOT}/config/facebooker.yml"

require 'facebooker'
FACEBOOKER = Facebooker.load_configuration(facebook_config)

# enable logger before including everything else, in case we ever want to log initialization 
Facebooker.logger = RAILS_DEFAULT_LOGGER if Object.const_defined? :RAILS_DEFAULT_LOGGER

require 'net/http_multipart_post'
require 'facebooker/rails/controller'
require 'facebooker/rails/facebook_url_rewriting'
require 'facebooker/rails/facebook_session_handling'
require 'facebooker/rails/facebook_asset_path'
require 'facebooker/rails/facebook_request_fix'
require 'facebooker/rails/routing'
require 'facebooker/rails/facebook_pretty_errors' rescue nil
require 'facebooker/rails/facebook_url_helper'
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

# When making get requests, Facebook sends fb_sig parameters both in the query string
# and also in the post body. We want to ignore the query string ones because they are one
# request out of date
# We only do thise when there are POST parameters so that IFrame linkage still works
class ActionController::AbstractRequest
  def query_parameters_with_facebooker
    if request_parameters.blank?
      query_parameters_without_facebooker
    else
      (query_parameters_without_facebooker||{}).reject {|key,value| key.to_s =~ /^fb_sig/}
    end
  end
  
  alias_method_chain :query_parameters, :facebooker
end

# We turn off route optimization to make named routes use our code for figuring out if they should go to the session
# If this fails, it means we're on rails 1.2, we can ignore it
begin
  ActionController::Base::optimise_named_routes = false 
rescue NoMethodError=>e
  nil
end

# pull :canvas=> into env in routing to allow for conditions
ActionController::Routing::RouteSet.send :include,  Facebooker::Rails::Routing::RouteSetExtensions
ActionController::Routing::RouteSet::Mapper.send :include, Facebooker::Rails::Routing::MapperExtensions
