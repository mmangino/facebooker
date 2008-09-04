begin
  unless Object.const_defined?("ActiveSupport") and ActiveSupport.const_defined?("JSON")
    require 'json' 
    module Facebooker
      def self.json_decode(str)
        JSON.parse(str)
      end
    end
  else
    module Facebooker
      def self.json_decode(str)
        ActiveSupport::JSON.decode(str)
      end
    end
  end 
rescue
  require 'json' 
end
require 'zlib'
require 'digest/md5'

require 'facebooker/batch_request'
require 'facebooker/feed'
require 'facebooker/logging'
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
require 'facebooker/models/page'
require 'facebooker/models/photo'
require 'facebooker/models/cookie'
require 'facebooker/models/applicationproperties'
require 'facebooker/models/tag'
require 'facebooker/models/user'
require 'facebooker/models/info_item'
require 'facebooker/models/info_section'
require 'facebooker/adapters/adapter_base'
require 'facebooker/adapters/facebook_adapter'
require 'facebooker/adapters/bebo_adapter'
require 'facebooker/models/friend_list'

module Facebooker
      
    class << self
    
    def load_configuration(facebooker_yaml_file)
      if File.exist?(facebooker_yaml_file)
        if defined? RAILS_ENV
          facebooker = YAML.load_file(facebooker_yaml_file)[RAILS_ENV] 
        else
          facebooker = YAML.load_file(facebooker_yaml_file)           
        end
        ENV['FACEBOOK_API_KEY'] = facebooker['api_key']
        ENV['FACEBOOK_SECRET_KEY'] = facebooker['secret_key']
        ENV['FACEBOOKER_RELATIVE_URL_ROOT'] = facebooker['canvas_page_name']
        ENV['FACEBOOKER_API'] = facebooker['api']
        if Object.const_defined?("ActionController")
          ActionController::Base.asset_host = facebooker['callback_url'] if(ActionController::Base.asset_host.blank?)
        end
        @facebooker_configuration = facebooker
      end
    end
    
    def facebooker_config
      @facebooker_configuration 
    end
    
     def current_adapter=(adapter_class)
      @current_adapter = adapter_class
    end
    
    def current_adapter
      @current_adapter || Facebooker::AdapterBase.default_adapter
    end
    
    def load_adapter(params)
      self.current_adapter = Facebooker::AdapterBase.load_adapter(params)
    end
      
    def facebook_path_prefix=(path)
      current_adapter.facebook_path_prefix = path
    end
  
    # Default is canvas_page_name in yml file
    def facebook_path_prefix
      current_adapter.facebook_path_prefix
    end
    
    def is_for?(application_container)
      current_adapter.is_for?(application_container)
    end
    
   
   
    [:api_key,:secret_key, :www_server_base_url,:login_url_base,:install_url_base,:api_rest_path,:api_server_base,:api_server_base_url,:canvas_server_base].each do |delegated_method|
      define_method(delegated_method){ return current_adapter.send(delegated_method)}
    end
    
    
       def path_prefix
      @path_prefix
      end
    
    
    # Set the asset path to the canvas path for just this one request
    # by definition, we will make this a canvas request
    def with_asset_path_for_canvas
      original_asset_host = ActionController::Base.asset_host
      begin
        ActionController::Base.asset_host = Facebooker.api_server_base_url
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
