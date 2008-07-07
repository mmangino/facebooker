module Facebooker
  class AdapterBase
    def facebook_path_prefix
      "/" + (@facebook_path_prefix || canvas_page_name || ENV['FACEBOOK_CANVAS_PATH'] || ENV['FACEBOOKER_RELATIVE_URL_ROOT'])
    end
          
    def facebook_path_prefix=(prefix)
      @facebook_path_prefix = prefix
    end
      
    def  facebooker_config
      @config
    end
      
    def api_server_base_url
      "http://" + api_server_base
    end
      
    def is_for?(application_context)
      raise "SubClassShouldDefine"
    end
       
    def initialize(config)
      @config = config
    end
       
    # TODO: Get someone to look into this for desktop apps.  
    def  self.facebooker_config
      return @facebooker_config if @facebooker_config
        
      facebook_config_file = "#{RAILS_ROOT}/config/facebooker.yml"
      if File.exist?(facebook_config_file)
        @facebooker_config = YAML.load_file(facebook_config_file)[RAILS_ENV]     
      end
    end
     
    def self.load_adapter(params)
      if(  ( api_key = ( params[:fb_sig_api_key] || facebooker_config["#{params[:config_key_base]}api_key"])))
         
        if(  facebooker_config)
          facebooker_config.each do |key,value|
            if(value == api_key)
              key_base = key.match(/(.*)[_]?api_key/)[1]
              adapter_class_name = key_base.blank? ? "FacebookAdapter" : facebooker_config[key_base + "adapter"]
              adpater_class = "Facebooker::#{adapter_class_name}".constantize
              # Collect the rest of the configuration
              adapter_config = {}
              facebooker_config.each do |key,value|
                next unless( match = key.match(/#{key_base}[_]?(.*)/))
                adapter_config[match[1]] = value
              end
              return adpater_class.new(adapter_config)
            end     
          end
        else
          self.default_adapter
        end
      else
        raise "UnableToLoadAdapter"
      end
    end
     
    def self.default_adapter
      if( facebooker_config.nil? || facebooker_config.blank? )
        config = { "api_key" => ENV['FACEBOOK_API_KEY'], "secret_key" =>  ENV['FACEBOOK_SECRET_KEY']}
      else
        config = facebooker_config
      end
      FacebookAdapter.new(config)
    end
     
    [:canvas_page_name, :api_key,:secret_key].each do |key_method|
      define_method(key_method){ return facebooker_config[key_method.to_s]}
    end
         
  end
   
  class FacebookAdapter < AdapterBase
         
    def canvas_server_base
      "apps.facebook.com"
    end
      
    def api_server_base
      ENV["FACEBOOKER_API"] == "new" ? "api.new.facebook.com" : "api.facebook.com"
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
       
    def www_server_base_url
      ENV["FACEBOOKER_API"] == "new" ? "www.new.facebook.com" : "www.facebook.com"
    end
       
    def login_url_base
      "http://#{www_server_base_url}/login.php?api_key=#{api_key}&v=1.0"
    end
       
    def install_url_base
      "http://#{www_server_base_url}/install.php?api_key=#{api_key}&v=1.0"
    end
    
  end
end


module Facebooker
  class BeboAdapter < AdapterBase
      
    def canvas_server_base
      "apps.bebo.com"
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

       
    def login_url_base
      options = default_login_url_options.merge(options)
      "http://#{www_server_base_url}/SignIn.jsp?ApiKey=#{api_key}&v=1.0"
    end

    def install_url_base
      "http://#{www_server_base_url}/c/apps/add?ApiKey=#{api_key}&v=1.0"
    end
  end
end