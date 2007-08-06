require 'digest/md5'
module Facebooker
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
    
    private
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
    
  end
end