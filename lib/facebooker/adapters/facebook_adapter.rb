module Facebooker
  class AdapterBase
    class << self
      def facebook_path_prefix
        "/" + (@facebook_path_prefix || canvas_page_name)
      end
          
      def facebook_path_prefix=(prefix)
        @facebook_path_prefix = prefix
      end
      
      def  facebooker_config
        return @facebooker_config if @facebooker_config
        
        facebook_config_file = "#{RAILS_ROOT}/config/facebooker.yml"
        if File.exist?(facebook_config_file)
          @facebooker_config = YAML.load_file(facebook_config_file)[RAILS_ENV]     
        end
      end
      
       def api_server_base_url
        "http://" + api_server_base
      end
      
       def is_for?(application_context)
         raise "SubClassShouldDefine"
       end
      
     
    end
    
  end
  class FacebookAdapter < AdapterBase
    class << self
      def canvas_page_name
        facebooker_config["canvas_page_name"]
      end
      def api_key
        facebooker_config["api_key"]
      end
      
      def secret_key
        facebooker_config["secret_key"]
      end
      
      def canvas_server_base
        "apps.facebook.com"
      end
      
      def api_server_base
          ENV["FACEBOOKER_API"] == "new" ? "api.new.facebook.com" : "api.facebook.com"
      end
    
      def api_rest_path
        "/restserver.php"
      end
      
       def is_for?(application_context)
         application_context == :facebook
       end
       
       def www_server_base_url
            ENV["FACEBOOKER_API"] == "new" ? "www.new.facebook.com" : "www.facebook.com"
       end
       
       def login_url_base(api_key)
         "http://#{Facebooker.www_server_base_url}/login.php?api_key=#{api_key}&v=1.0"
       end
       
       def install_url_base(api_key)
         "http://#{Facebooker.www_server_base_url}/install.php?api_key=#{api_key}&v=1.0"
       end
    
  end
  end
end


module Facebooker
  class BeboAdapter < AdapterBase
    class << self
      def canvas_page_name
        facebooker_config["bebo_canvas_page_name"]
      end
      def canvas_server_base
        "apps.bebo.com"
      end
      
      def api_key
        facebooker_config["bebo_api_key"]
      end
      
      def secret_key
        facebooker_config["bebo_secret_key"]
      end
     
       def api_server_base
        'apps.bebo.com'
      end
    
      def api_rest_path
        "/restserver.php"
      end
      
       def is_for?(application_context)
         application_context == :bebo
       end
       
      def www_server_base_url
            "www.bebo.com"
       end

       
       def login_url_base(api_key)
      options = default_login_url_options.merge(options)
      "http://#{Facebooker.www_server_base_url}/SignIn.jsp?ApiKey=#{api_key}&v=1.0"
    end

    def install_url_base(api_key)
      "http://#{Facebooker.www_server_base_url}/c/apps/add?ApiKey=#{api_key}&v=1.0"
    end
    end
  end
end