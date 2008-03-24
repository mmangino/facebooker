require 'json' 
require 'facebooker/batch_request'
require 'facebooker/feed'
require 'facebooker/model'
require 'facebooker/parser'
require 'facebooker/service'
require 'facebooker/server_cache'
require 'facebooker/data'
require 'facebooker/admin'
require 'facebooker/session'
require 'facebooker/version'
require 'facebooker/models/location'
require 'facebooker/models/affiliation'
require 'facebooker/models/album'
require 'facebooker/models/education_info'
require 'facebooker/models/work_info'
require 'facebooker/models/event'
require 'facebooker/models/group'
require 'facebooker/models/notifications'
require 'facebooker/models/photo'
require 'facebooker/models/cookie'
require 'facebooker/models/applicationproperties'
require 'facebooker/models/tag'
require 'facebooker/models/user'

module Facebooker
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
