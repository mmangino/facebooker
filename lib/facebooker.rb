require 'json'

require 'facebooker/affiliation'
require 'facebooker/album'
require 'facebooker/education_info'
require 'facebooker/feed'
require 'facebooker/location'
require 'facebooker/model'
require 'facebooker/notifications'
require 'facebooker/parser'
require 'facebooker/photo'
require 'facebooker/cookie'
require 'facebooker/service'
require 'facebooker/server_cache'
require 'facebooker/data'
require 'facebooker/admin'
require 'facebooker/applicationproperties'
require 'facebooker/session'
require 'facebooker/tag'
require 'facebooker/user'
require 'facebooker/version'
require 'facebooker/work_info'
require 'facebooker/event'
require 'facebooker/group'
module Facebooker
  VERSION="0.9.5"
  class << self
    def path_prefix
      @path_prefix
    end
  
    def facebook_path_prefix=(path)
      @facebook_path_prefix = path
    end
  
    def facebook_path_prefix
      "/" + (@facebook_path_prefix || ENV["FACEBOOK_CANVAS_PATH"] || ENV["FACEBOOKER_RELATIVE_URL_ROOT"])
    end
  
    # Set the asset path to the canvas path for just this one request
    # by definition, we will make this a canvas request
    def with_asset_path_for_canvas
      original_asset_host = ActionController::Base.asset_host
      begin
        ActionController::Base.asset_host = "http://apps.facebook.com"
        request_for_canvas(true) do
          yield
        end
      ensure
        ActionController::Base.asset_host = original_asset_host
      end
    end
  
    # If this request is_canvas_request
    # then use the application name as the url root
    def request_for_canvas(is_canvas_request)
      original_path_prefix = @path_prefix 
      begin
        @path_prefix = facebook_path_prefix if is_canvas_request
        yield
      ensure
        @path_prefix = original_path_prefix
      end
    end
  end
end
