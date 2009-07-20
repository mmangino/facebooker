module Facebooker

  class AdapterBase
    class UnableToLoadAdapter < Exception; end
    require 'active_support/inflector'
    include  ActiveSupport::CoreExtensions::String::Inflections
    def facebook_path_prefix
      "/" + (@facebook_path_prefix || canvas_page_name || ENV['FACEBOOK_CANVAS_PATH'] || ENV['FACEBOOKER_RELATIVE_URL_ROOT'])
    end

    def facebook_path_prefix=(prefix)
      @facebook_path_prefix = prefix
    end

    def facebooker_config
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
      @facebook_path_prefix = nil
    end

    def  self.facebooker_config
      Facebooker.facebooker_config
    end


    def self.load_adapter(params)

      config_key_base = params[:config_key_base] # This allows for loading of a aspecific adapter
      config_key_base += "_" if config_key_base && config_key_base.length > 0

      unless api_key = (params[:fb_sig_api_key] || facebooker_config["#{config_key_base}api_key"])
        raise Facebooker::AdapterBase::UnableToLoadAdapter
      end

      unless facebooker_config
        return self.default_adapter(params)
      end

      facebooker_config.each do |key,value|
        next unless value == api_key

        key_base = key.match(/(.*)[_]?api_key/)[1]

        adapter_class_name = if !key_base || key_base.length == 0
           "FacebookAdapter"
        else
          facebooker_config[key_base + "adapter"]
        end

        adapter_class = "Facebooker::#{adapter_class_name}".constantize

        # Collect the rest of the configuration
        adapter_config = {}
        facebooker_config.each do |key,value|
          if (match = key.match(/#{key_base}[_]?(.*)/))
            adapter_config[match[1]] = value
          end
        end
        return adapter_class.new(adapter_config)
      end

      return self.default_adapter(params)

    end

    def self.default_adapter(params = {})
      if facebooker_config.nil? || (facebooker_config.blank? rescue nil)
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
end
