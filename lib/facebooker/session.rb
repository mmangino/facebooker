require 'digest/md5'
module Facebooker
  #
  # Raised when trying to perform an operation on a user
  # other than the logged in user (if that's unallowed)
  class NonSessionUser < Exception;  end
  class Session
    class SessionExpired < Exception; end
    class UnknownError < Exception; end
    class ServiceUnavailable < Exception; end
    class MaxRequestsDepleted < Exception; end
    class HostNotAllowed < Exception; end
    class MissingOrInvalidParameter < Exception; end
    class InvalidAPIKey < Exception; end
    class SessionExpired < Exception; end
    class CallOutOfOrder < Exception; end
    class IncorrectSignature     < Exception; end
    class ConfigurationMissing < Exception; end

    API_SERVER_BASE_URL       = "api.facebook.com"
    API_PATH_REST             = "/restserver.php"
    WWW_SERVER_BASE_URL       = "www.facebook.com"
    WWW_PATH_LOGIN            = "/login.php"
    WWW_PATH_ADD              = "/add.php"
    WWW_PATH_INSTALL          = "/install.php"
        
    def self.create(api_key, secret_key)
      raise ArgumentError unless !api_key.nil? && !secret_key.nil?
      new(api_key, secret_key)
    end
    
    def self.api_key
      extract_key_from_environment(:api) || extract_key_from_configuration_file(:api) rescue report_inability_to_find_key(:api)
    end
    
    def self.secret_key
      extract_key_from_environment(:secret) || extract_key_from_configuration_file(:secret) rescue report_inability_to_find_key(:secret)
    end
    
    def login_url
      "http://www.facebook.com/login.php?api_key=#{@api_key}&v=1.0"
    end
  
    def initialize(api_key, secret_key)
      @api_key = api_key
      @secret_key = secret_key
    end
    
    def secret_for_method(method_name)
      @secret_key
    end
      
    def auth_token
      @auth_token ||= post 'facebook.auth.createToken'
    end
    
    def infinite?
      @expires == 0
    end
    
    def expired?
      @expires.nil? || (!infinite? && Time.at(@expires) <= Time.now)
    end
    
    def secured?
      !@session_key.nil? && !expired?
    end
    
    def secure!
      response = post 'facebook.auth.getSession', :auth_token => auth_token
      @session_key = response['session_key']
      @uid = Integer(response['uid'])
      @expires = Integer(response['expires'])
      @secret_from_session = response['secret']
    end    
    
    def user
      @user ||= User.new(uid, self)
    end
    
    def get_albums(album_ids)
      @albums ||= post('facebook.photos.getAlbums', :aids => album_ids).map do |hash|
        Album.from_hash(hash)
      end
    end
    
    def send_notification(user_ids, fbml, email_fbml = nil)
      params = {:notification => fbml, :to_ids => user_ids.join(',')}
      if email_fbml
        params[:email] = email_fbml
      end
      post 'facebook.notifications.send', params
    end

    def send_request(user_ids, request_type, content, image_url)
      send_request_or_invitation(user_ids, request_type, content, image_url, false)      
    end

    def send_invitation(user_ids, invitation_type, content, image_url)
      send_request_or_invitation(user_ids, invitation_type, content, image_url, true)
    end
    
    def marshal_load(variables)#:nodoc:
      @session_key, @uid, @expires, @secret_from_session, @auth_token = variables
    end
    
    def marshal_dump#:nodoc:
      [@session_key, @uid, @expires, @secret_from_session, @auth_token]
    end
    
    class Desktop < Session
      def login_url
        super + "&auth_token=#{auth_token}"
      end

      def secret_for_method(method_name)
        secret = auth_request_methods.include?(method_name) ? super : @secret_from_session
        secret
      end
      
      def post(method, params = {})
        if method == 'facebook.profile.getFBML' || method == 'facebook.profile.setFBML'
          raise NonSessionUser.new("User #{@uid} is not the logged in user.") unless @uid == params[:uid]
        end
        super
      end
      private
        def auth_request_methods
          ['facebook.auth.getSession', 'facebook.auth.createToken']
        end
    end

    
    def post(method, params = {})
      params[:method] = method
      params[:api_key] = @api_key
      params[:call_id] = Time.now.to_f.to_s unless method == 'facebook.auth.getSession'
      params[:v] = "1.0"
      @session_key && params[:session_key] ||= @session_key
      service.post(params.merge(:sig => signature_for(params)))      
    end
    
    def self.configuration_file_path
      @configuration_file_path || File.expand_path("~/.facebookerrc")
    end
    
    def self.configuration_file_path=(path)
      @configuration_file_path = path
    end
    
    private
    def self.extract_key_from_environment(key_name)
      val = ENV["FACEBOOK_" + key_name.to_s.upcase + "_KEY"]
    end
    
    def self.extract_key_from_configuration_file(key_name)
      read_configuration_file[key_name]
    end
    
    def self.report_inability_to_find_key(key_name)
      raise ConfigurationMissing, "Could not find configuration information for #{key_name}"
    end
    
    def self.read_configuration_file
      eval(File.read(configuration_file_path))
    end
    
    def service
      @service ||= Service.new(API_SERVER_BASE_URL, API_PATH_REST, @api_key)      
    end
    
    def uid
      @uid || (secure!; @uid)
    end
      
    def signature_for(params)
      raw_string = params.inject([]) do |collection, pair|
        collection << pair.join("=")
        collection
      end.sort.join
      Digest::MD5.hexdigest([raw_string, secret_for_method(params[:method])].join)
    end
        
    def send_request_or_invitation(user_ids, request_type, content, image_url, invitation)
      params = {:to_ids => user_ids, :type => request_type, :content => content, :image => image_url, :invitation => invitation}
      post 'facebook.notifications.sendRequest', params
    end    
  end
end