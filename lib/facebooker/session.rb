require 'digest/md5'
require 'cgi'

module Facebooker
  #
  # Raised when trying to perform an operation on a user
  # other than the logged in user (if that's unallowed)
  class NonSessionUser < StandardError;  end
  class Session
    class SessionExpired < StandardError; end
    class UnknownError < StandardError; end
    class ServiceUnavailable < StandardError; end
    class MaxRequestsDepleted < StandardError; end
    class HostNotAllowed < StandardError; end
    class MissingOrInvalidParameter < StandardError; end
    class InvalidAPIKey < StandardError; end
    class SessionExpired < StandardError; end
    class CallOutOfOrder < StandardError; end
    class IncorrectSignature     < StandardError; end
    class SignatureTooOld     < StandardError; end
    class TooManyUserCalls < StandardError; end
    class TooManyUserActionCalls < StandardError; end
    class InvalidFeedTitleLink < StandardError; end
    class InvalidFeedTitleLength < StandardError; end
    class InvalidFeedTitleName < StandardError; end
    class BlankFeedTitle < StandardError; end
    class FeedBodyLengthTooLong < StandardError; end
    class InvalidFeedPhotoSource < StandardError; end
    class InvalidFeedPhotoLink < StandardError; end    
    class FeedMarkupInvalid < StandardError; end
    class FeedTitleDataInvalid < StandardError; end
    class FeedTitleTemplateInvalid < StandardError; end
    class FeedBodyDataInvalid < StandardError; end
    class FeedBodyTemplateInvalid < StandardError; end
    class FeedPhotosNotRetrieved < StandardError; end
    class FeedTargetIdsInvalid < StandardError; end
    class ConfigurationMissing < StandardError; end
    class FQLParseError < StandardError; end
    class FQLFieldDoesNotExist < StandardError; end
    class FQLTableDoesNotExist < StandardError; end
    class FQLStatementNotIndexable < StandardError; end
    class FQLFunctionDoesNotExist < StandardError; end
    class FQLWrongNumberArgumentsPassedToFunction < StandardError; end
    class InvalidAlbumId < StandardError; end
    class AlbumIsFull < StandardError; end
    class MissingOrInvalidImageFile < StandardError; end
    class TooManyUnapprovedPhotosPending < StandardError; end
  
    API_SERVER_BASE_URL       = "api.facebook.com"
    API_PATH_REST             = "/restserver.php"
    WWW_SERVER_BASE_URL       = "www.facebook.com"
    WWW_PATH_LOGIN            = "/login.php"
    WWW_PATH_ADD              = "/add.php"
    WWW_PATH_INSTALL          = "/install.php"
    
    attr_writer :auth_token
    attr_reader :session_key
    
    def self.create(api_key=nil, secret_key=nil)
      api_key ||= self.api_key
      secret_key ||= self.secret_key
      raise ArgumentError unless !api_key.nil? && !secret_key.nil?
      new(api_key, secret_key)
    end
    
    def self.api_key
      extract_key_from_environment(:api) || extract_key_from_configuration_file(:api) rescue report_inability_to_find_key(:api)
    end
    
    def self.secret_key
      extract_key_from_environment(:secret) || extract_key_from_configuration_file(:secret) rescue report_inability_to_find_key(:secret)
    end
    
    def self.current
      @current_session
    end
    
    def self.current=(session)
      @current_session=session
    end
    
    def login_url(options={})
      options = default_login_url_options.merge(options)
      "http://www.facebook.com/login.php?api_key=#{@api_key}&v=1.0#{login_url_optional_parameters(options)}"
    end

    def install_url(options={})
      "http://www.facebook.com/install.php?api_key=#{@api_key}&v=1.0#{install_url_optional_parameters(options)}"
    end

    def install_url_optional_parameters(options)
      optional_parameters = []
      optional_parameters << "&next=#{CGI.escape(options[:next])}" if options[:next]
      optional_parameters.join
    end

    def login_url_optional_parameters(options)
      # It is important that unused options are omitted as stuff like &canvas=false will still display the canvas. 
      optional_parameters = []
      optional_parameters << "&next=#{CGI.escape(options[:next])}" if options[:next]
      optional_parameters << "&skipcookie=true" if options[:skip_cookie]
      optional_parameters << "&hide_checkbox=true" if options[:hide_checkbox]
      optional_parameters << "&canvas=true" if options[:canvas]
      optional_parameters.join
    end
  
    def default_login_url_options
      {}
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
      secure_with!(response['session_key'], response['uid'], response['expires'], response['secret'])
    end    
    
    def secure_with!(session_key, uid, expires, secret_from_session = nil)
      @session_key = session_key
      @uid = Integer(uid)
      @expires = Integer(expires)
      @secret_from_session = secret_from_session
    end
    
    def fql_query(query, format = 'XML')
      post('facebook.fql.query', :query => query, :format => format) do |response|
        type = response.shift
        return [] if type.nil?
        response.shift.map do |hash|
          case type
          when 'user'
            user = User.new
            user.session = self
            user.populate_from_hash!(hash)
            user
          when 'photo'
            Photo.from_hash(hash)
          when 'event_member'
            Event::Attendance.from_hash(hash)
          end
        end        
      end
    end
    
    def user
      @user ||= User.new(uid, self)
    end
    
    #
    # This one has so many parameters, a Hash seemed cleaner than a long param list.  Options can be:
    # :uid => Filter by events associated with a user with this uid
    # :eids => Filter by this list of event ids. This is a comma-separated list of eids.
    # :start_time => Filter with this UTC as lower bound. A missing or zero parameter indicates no lower bound. (Time or Integer)
    # :end_time => Filter with this UTC as upper bound. A missing or zero parameter indicates no upper bound. (Time or Integer)
    # :rsvp_status => Filter by this RSVP status.
    def events(options = {})
      @events ||= post('facebook.events.get', options) do |response|
        response.map do |hash|
          Event.from_hash(hash)
        end
      end
    end
    
    def event_members(eid)
      @members ||= post('facebook.events.getMembers', :eid => eid) do |response|
        response.map do |attendee_hash|
          Event::Attendance.from_hash(attendee_hash)
        end
      end
    end
    
    
    #
    # Returns a proxy object for handling calls to Facebook cached items
    # such as images and FBML ref handles
    def server_cache
      Facebooker::ServerCache.new(self)
    end
    
    #
    # Returns a proxy object for handling calls to the Facebook Data API
    def data
      Facebooker::Data.new(self)
    end
    
    def admin
      Facebooker::Admin.new(self)
    end
    
    #
    # Given an array like:
    # [[userid, otheruserid], [yetanotherid, andanotherid]]
    # returns a Hash indicating friendship of those pairs:
    # {[userid, otheruserid] => true, [yetanotherid, andanotherid] => false}
    # if one of the Hash values is nil, it means the facebook platform's answer is "I don't know"
    def check_friendship(array_of_pairs_of_users)
      uids1 = []
      uids2 = []
      array_of_pairs_of_users.each do |pair|
        uids1 = pair.first
        uids2 = pair.last
      end
      post('facebook.friends.areFriends', :uids1 => uids1, :uids2 => uids2)
    end
    
    def get_photos(pids = nil, subj_id = nil,  aid = nil)
      if [subj_id, pids, aid].all? {|arg| arg.nil?}
        raise ArgumentError, "Can't get a photo without a picture, album or subject ID" 
      end
      @photos = post('facebook.photos.get', :subj_id => subj_id, :pids => pids, :aid => aid ) do |response|
        response.map do |hash|
          Photo.from_hash(hash)
        end
      end
    end
    
    def get_albums(aids)
      @albums = post('facebook.photos.getAlbums', :aids => aids) do |response|
        response.map do |hash|        
          Album.from_hash(hash)
        end
      end
    end
    
    def get_tags(pids)
      @tags = post('facebook.photos.getTags', :pids => pids)  do |response|
        response.map do |hash|
          Tag.from_hash(hash)
        end
      end
    end
    
    def add_tags(pid, x, y, tag_uid = nil, tag_text = nil )
      if [tag_uid, tag_text].all? {|arg| arg.nil?}
        raise ArgumentError, "Must enter a name or string for this tag"        
      end
      @tags = post('facebook.photos.addTag', :pid => pid, :tag_uid => tag_uid, :tag_text => tag_text, :x => x, :y => y )
    end
    
    def send_notification(user_ids, fbml, email_fbml = nil)
      params = {:notification => fbml, :to_ids => user_ids.map{ |id| User.cast_to_facebook_id(id)}.join(',')}
      if email_fbml
        params[:email] = email_fbml
      end
      post 'facebook.notifications.send', params
    end 

    ##
    # Send email to as many as 100 users at a time
	  def send_email(user_ids, subject, text, fbml = nil) 			
		  user_ids = Array(user_ids)
      params = {:fbml => fbml, :recipients => user_ids.map{ |id| User.cast_to_facebook_id(id)}.join(','), :text => text, :subject => subject} 
      post 'facebook.notifications.sendEmail', params
    end

    # Only serialize the bare minimum to recreate the session.
    def marshal_load(variables)#:nodoc:
      fields_to_serialize.each_with_index{|field, index| instance_variable_set_value(field, variables[index])}
    end
    
    # Only serialize the bare minimum to recreate the session.    
    def marshal_dump#:nodoc:
      fields_to_serialize.map{|field| instance_variable_value(field)}
    end
    
    # Only serialize the bare minimum to recreate the session. 
    def to_yaml( opts = {} )
      YAML::quick_emit(self.object_id, opts) do |out|
        out.map(taguri) do |map|
          fields_to_serialize.each do |field|
            map.add(field, instance_variable_value(field))
          end
        end
      end
    end
    
    def instance_variable_set_value(field, value)
      self.instance_variable_set("@#{field}", value)
    end
    
    def instance_variable_value(field)
      self.instance_variable_get("@#{field}")
    end
    
    def fields_to_serialize
      %w(session_key uid expires secret_from_session auth_token api_key secret_key)
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
    
    def batch_request?
      @batch_request
    end
    
    def add_to_batch(req,&proc)
      batch_request = BatchRequest.new(req,proc)
      @batch_queue<<batch_request
      batch_request
    end
    
    # Submit the enclosed requests for this session inside a batch
    # 
    # All requests will be sent to Facebook at the end of the block
    # each method inside the block will return a proxy object
    # attempting to access the proxy before the end of the block will yield an exception
    #
    # For Example:
    #
    #   facebook_session.batch do
    #     @send_result = facebook_session.send_notification([12451752],"Woohoo")
    #     @albums = facebook_session.user.albums
    #   end
    #   puts @albums.first.inspect
    #
    # is valid, however
    #
    #   facebook_session.batch do
    #     @send_result = facebook_session.send_notification([12451752],"Woohoo")
    #     @albums = facebook_session.user.albums
    #     puts @albums.first.inspect
    #   end
    #
    # will raise Facebooker::BatchRequest::UnexecutedRequest
    #
    # If an exception is raised while processing the result, that exception will be
    # re-raised on the next access to that object or when exception_raised? is called
    #
    # for example, if the send_notification resulted in TooManyUserCalls being raised,
    # calling 
    #   @send_result.exception_raised? 
    # would re-raise that exception
    # if there was an error retrieving the albums, it would be re-raised when 
    #  @albums.first 
    # is called
    #
    def batch(serial_only=false)
      @batch_request=true
      @batch_queue=[]
      yield
      # Set the batch request to false so that post will execute the batch job
      @batch_request=false
      BatchRun.current_batch=@batch_queue
      post("facebook.batch.run",:method_feed=>@batch_queue.map{|q| q.uri}.to_json,:serial_only=>serial_only.to_s)
    ensure
      @batch_request=false
      BatchRun.current_batch=nil
    end
    
    def post(method, params = {},&proc)
      add_facebook_params(params, method)
      @session_key && params[:session_key] ||= @session_key
      final_params=params.merge(:sig => signature_for(params))
      if batch_request?
        add_to_batch(final_params,&proc)
      else
        result=service.post(final_params)
        result = yield result if block_given?
        result
      end
    end
    
    def post_file(method, params = {})
      add_facebook_params(params, method)
      @session_key && params[:session_key] ||= @session_key
      service.post_file(params.merge(:sig => signature_for(params.reject{|key, value| key.nil?})))
    end
    
    
    def self.configuration_file_path
      @configuration_file_path || File.expand_path("~/.facebookerrc")
    end
    
    def self.configuration_file_path=(path)
      @configuration_file_path = path
    end
    
    private
      def add_facebook_params(hash, method)
        hash[:method] = method
        hash[:api_key] = @api_key
        hash[:call_id] = Time.now.to_f.to_s unless method == 'facebook.auth.getSession'
        hash[:v] = "1.0"
      end
    
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
  end
  
  class CanvasSession < Session
    def default_login_url_options
      {:canvas => true}
    end
  end
end
