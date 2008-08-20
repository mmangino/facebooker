module Facebooker
  
   
  class FacebookAdapter < AdapterBase
      
    def canvas_server_base
      FacebookAdapter.new_api? ? "apps.new.facebook.com" : "apps.facebook.com"
    end
      
    def api_server_base
       FacebookAdapter.new_api? ? "api.new.facebook.com" : "api.facebook.com"
    end
    
      def www_server_base_url
      FacebookAdapter.new_api? ? "www.new.facebook.com" : "www.facebook.com"
    end
    
    def api_rest_path
      "/restserver.php"
    end
    
    def api_key
      ENV['FACEBOOK_API_KEY'] || super      
    end
    
    def secret_key
      ENV['FACEBOOK_SECRET_KEY'] || super
    end
      
    def is_for?(application_context)
      application_context == :facebook
    end
       
  
       
    def login_url_base
      "http://#{www_server_base_url}/login.php?api_key=#{api_key}&v=1.0"
    end
       
    def install_url_base
      "http://#{www_server_base_url}/install.php?api_key=#{api_key}&v=1.0"
    end
    
  end
  
  class FacebookNewAdapter < FacebookAdapter
      def canvas_server_base
      "apps.new.facebook.com" 
    end
      
    def api_server_base
       "api.new.facebook.com"
    end
    
      def www_server_base_url
     "www.new.facebook.com" 
    end
  end
end


