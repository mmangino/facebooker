unless defined?(ActiveSupport) and defined?(ActiveSupport::JSON)
  require 'json'
  module Facebooker
    def self.json_decode(str)
      JSON.parse(str)
    end

    def self.json_encode(o)
      JSON.dump(o)
    end
  end
else
  module Facebooker
    def self.json_decode(str)
      ActiveSupport::JSON.decode(str)
    end

    def self.json_encode(o)
      ActiveSupport::JSON.encode(o)
    end
  end
end

require 'zlib'
require 'digest/md5'

module Facebooker

  @facebooker_configuration = {}
  @raw_facebooker_configuration = {}
  @current_adapter = nil
  @set_asset_host_to_callback_url = true
  @path_prefix = nil
  @use_curl    = false

  class << self

    def load_configuration(facebooker_yaml_file)
      return false unless File.exist?(facebooker_yaml_file)
      @raw_facebooker_configuration = YAML.load(ERB.new(File.read(facebooker_yaml_file)).result)
      if defined? RAILS_ENV
        @raw_facebooker_configuration = @raw_facebooker_configuration[RAILS_ENV]
      end
      Thread.current[:fb_api_config] = @raw_facebooker_configuration unless Thread.current[:fb_api_config]
      apply_configuration(@raw_facebooker_configuration)
    end

    # Sets the Facebook environment based on a hash of options. 
    # By default the hash passed in is loaded from facebooker.yml, but it can also be passed in
    # manually every request to run multiple Facebook apps off one Rails app. 
    def apply_configuration(config)
      ENV['FACEBOOK_API_KEY']             = config['api_key']
      ENV['FACEBOOK_SECRET_KEY']          = config['secret_key']
      ENV['FACEBOOKER_RELATIVE_URL_ROOT'] = config['canvas_page_name']
      ENV['FACEBOOKER_API']               = config['api']
      if config.has_key?('set_asset_host_to_callback_url')
        Facebooker.set_asset_host_to_callback_url = config['set_asset_host_to_callback_url'] 
      end
      if Object.const_defined?("ActionController") and Facebooker.set_asset_host_to_callback_url
        ActionController::Base.asset_host = config['callback_url'] 
      end
      Facebooker.timeout = config['timeout']

      @facebooker_configuration = config  # must be set before adapter loaded
      load_adapter(:fb_sig_api_key => config['api_key'])
      facebooker_config
    end

    def facebooker_config
      @facebooker_configuration
    end

    def with_application(api_key, &block)
      config = fetch_config_for( api_key )

      unless config
        self.logger.info "Can't find facebooker config: '#{api_key}'" if self.logger
        yield if block_given?
        return
      end

      # Save the old config to handle nested activation. If no app context is
      # set yet, use default app's configuration.
      old = Thread.current[:fb_api_config] ? Thread.current[:fb_api_config].dup : @raw_facebooker_configuration

      if block_given?
        begin
          self.logger.info "Swapping facebooker config: '#{api_key}'" if self.logger
          Thread.current[:fb_api_config] = apply_configuration(config)
          yield
        ensure
          Thread.current[:fb_api_config] = old if old && !old.empty?
          apply_configuration(Thread.current[:fb_api_config])
        end
      end
    end

    def all_api_keys
      [
        @raw_facebooker_configuration['api_key']
      ] + (
        @raw_facebooker_configuration['alternative_keys'] ?
        @raw_facebooker_configuration['alternative_keys'].keys :
        []
      )
    end

    def with_all_applications(&block)
      all_api_keys.each do |current_api_key|
        with_application(current_api_key) do
          block.call
        end
      end
    end

    def fetch_config_for(api_key)
      if @raw_facebooker_configuration['api_key'] == api_key
        return @raw_facebooker_configuration
      elsif @raw_facebooker_configuration['alternative_keys'] and
            @raw_facebooker_configuration['alternative_keys'].keys.include?(api_key)
        return @raw_facebooker_configuration['alternative_keys'][api_key].merge(
                'api_key' => api_key )
      end
      return false
    end

    # TODO: This should be converted to attr_accessor, but we need to
    # get all the require statements at the top of the file to work.

    # Set the current adapter
    attr_writer :current_adapter

    # Get the current adapter
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

    attr_accessor :set_asset_host_to_callback_url
    attr_accessor :use_curl
    alias :use_curl? :use_curl

    def timeout=(val)
      @timeout = val.to_i
    end

    def timeout
      @timeout
    end

    [:api_key,:secret_key, :www_server_base_url,:login_url_base,:install_url_base,:permission_url_base,:connect_permission_url_base,:api_rest_path,:api_server_base,:api_server_base_url,:canvas_server_base, :video_server_base].each do |delegated_method|
      define_method(delegated_method){ return current_adapter.send(delegated_method)}
    end


    attr_reader :path_prefix


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

require 'facebooker/attachment'
require 'facebooker/batch_request'
require 'facebooker/feed'
require 'facebooker/logging'
require 'facebooker/model'
require 'facebooker/parser'
require 'facebooker/service'
require 'facebooker/service/base_service'
#optional HTTP service adapters
begin
  require 'facebooker/service/curl_service' 
rescue LoadError
  nil
end
begin
  require 'facebooker/service/typhoeus_service'
  require 'facebooker/service/typhoeus_multi_service'
rescue LoadError
  nil
end

require 'facebooker/service/net_http_service'
require 'facebooker/server_cache'
require 'facebooker/data'
require 'facebooker/admin'
require 'facebooker/application'
require 'facebooker/mobile'
require 'facebooker/session'
require 'facebooker/stream_post'
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
require 'facebooker/models/applicationrestrictions'
require 'facebooker/models/tag'
require 'facebooker/models/user'
require 'facebooker/models/info_item'
require 'facebooker/models/info_section'
require 'facebooker/models/friend_list'
require 'facebooker/models/video'
require 'facebooker/adapters/adapter_base'
require 'facebooker/adapters/facebook_adapter'
require 'facebooker/adapters/bebo_adapter'
