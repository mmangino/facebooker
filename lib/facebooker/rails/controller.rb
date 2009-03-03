require 'facebooker'
require 'facebooker/rails/profile_publisher_extensions'
module Facebooker
  module Rails
    module Controller
      include Facebooker::Rails::ProfilePublisherExtensions
      def self.included(controller)
        controller.extend(ClassMethods)
        #controller.before_filter :set_adapter <-- security hole noted by vchu
        controller.before_filter :set_facebook_request_format
        controller.helper_attr :facebook_session_parameters
        controller.helper_method :request_comes_from_facebook?
      end

    
      def facebook_session
        @facebook_session
      end
      
      def facebook_session_parameters
        {:fb_sig_session_key=>params[:fb_sig_session_key]}
      end
      
      def create_facebook_session
        secure_with_facebook_params! || secure_with_cookies! || secure_with_token!
      end
      
      def set_facebook_session
        # first, see if we already have a session
        session_set = session_already_secured?
        # if not, see if we can load it from the environment
        unless session_set
          session_set = create_facebook_session
          session[:facebook_session] = @facebook_session if session_set
        end
        if session_set
          capture_facebook_friends_if_available! 
          Session.current = facebook_session
        end
        return session_set
      end
      
      
      def facebook_params
        @facebook_params ||= verified_facebook_params
      end      
      
      def redirect_to(*args)
        if request_is_for_a_facebook_canvas? and !request_is_facebook_tab?
          render :text => fbml_redirect_tag(*args)
        else
          super
        end
      end
            
      private
      
      def session_already_secured?
        (@facebook_session = session[:facebook_session]) && session[:facebook_session].secured? if valid_session_key_in_session?
      end
      
      def user_has_deauthorized_application?
        # if we're inside the facebook session and there is no session key,
        # that means the user revoked our access
        # we don't want to keep using the old expired key from the cookie. 
        request_comes_from_facebook? and params[:fb_sig_session_key].blank?
      end
      
      def clear_facebook_session_information
        session[:facebook_session] = nil
        @facebook_session=nil        
      end
      
      def valid_session_key_in_session?
        #before we access the facebook_params, make sure we have the parameters
        #otherwise we will blow up trying to access the secure parameters
        if user_has_deauthorized_application?
          clear_facebook_session_information
          false
        else
          !session[:facebook_session].blank? &&  (params[:fb_sig_session_key].blank? || session[:facebook_session].session_key == facebook_params[:session_key])
        end
      end
      
      def clear_fb_cookies!
        domain_cookie_tag = "base_domain_#{Facebooker.api_key}"
        cookie_domain = ".#{cookies[domain_cookie_tag]}" if cookies[domain_cookie_tag]
        fb_cookie_names.each {|name| cookies.delete(name, :domain=>cookie_domain)}
        cookies.delete Facebooker.api_key
      end

      def fb_cookie_prefix
        Facebooker.api_key+"_"
      end

      def fb_cookie_names
        fb_cookie_names = cookies.keys.select{|k| k.starts_with?(fb_cookie_prefix)}
      end

      def secure_with_cookies!
          parsed = {}
          
          fb_cookie_names.each { |key| parsed[key[fb_cookie_prefix.size,key.size]] = cookies[key] }
 
          #returning gracefully if the cookies aren't set or have expired
          return unless parsed['session_key'] && parsed['user'] && parsed['expires'] && parsed['ss'] 
          return unless Time.at(parsed['expires'].to_f) > Time.now || (parsed['expires'] == "0")
          
          #if we have the unexpired cookies, we'll throw an exception if the sig doesn't verify
          verify_signature(parsed,cookies[Facebooker.api_key])
          
          @facebook_session = new_facebook_session
          @facebook_session.secure_with!(parsed['session_key'],parsed['user'],parsed['expires'],parsed['ss'])
          @facebook_session
      end
    
      def secure_with_token!
        if params['auth_token']
          @facebook_session = new_facebook_session
          @facebook_session.auth_token = params['auth_token']
          @facebook_session.secure!
          @facebook_session
        end
      end
      
      def secure_with_facebook_params!
        return unless request_comes_from_facebook?
        
        if ['user', 'session_key'].all? {|element| facebook_params[element]}
          @facebook_session = new_facebook_session
          @facebook_session.secure_with!(facebook_params['session_key'], facebook_params['user'], facebook_params['expires'])
          @facebook_session
        end
      end
      
      #override to specify where the user should be sent after logging in
      def after_facebook_login_url
        nil
      end
      
      def create_new_facebook_session_and_redirect!
        session[:facebook_session] = new_facebook_session
        url_params = after_facebook_login_url.nil? ? {} : {:next=>after_facebook_login_url}
        redirect_to session[:facebook_session].login_url(url_params) unless @installation_required
        false
      end
      
      def new_facebook_session
        Facebooker::Session.create(Facebooker.api_key, Facebooker.secret_key)
      end
      
      def capture_facebook_friends_if_available!
        return unless request_comes_from_facebook?
        if friends = facebook_params['friends']
          facebook_session.user.friends = friends.map do |friend_uid|
            User.new(friend_uid, facebook_session)
          end
        end
      end
            
      def blank?(value)
        (value == '0' || value.nil? || value == '')        
      end

      def verified_facebook_params
        facebook_sig_params = params.inject({}) do |collection, pair|
          collection[pair.first.sub(/^fb_sig_/, '')] = pair.last if pair.first[0,7] == 'fb_sig_'
          collection
        end
        verify_signature(facebook_sig_params,params['fb_sig'])

        facebook_sig_params.inject(HashWithIndifferentAccess.new) do |collection, pair| 
          collection[pair.first] = facebook_parameter_conversions[pair.first].call(pair.last)
          collection
        end
      end
      
      def earliest_valid_session
        48.hours.ago
      end
      
      def verify_signature(facebook_sig_params,expected_signature)
        raw_string = facebook_sig_params.map{ |*args| args.join('=') }.sort.join
        actual_sig = Digest::MD5.hexdigest([raw_string, Facebooker::Session.secret_key].join)
        raise Facebooker::Session::IncorrectSignature if actual_sig != expected_signature
        raise Facebooker::Session::SignatureTooOld if facebook_sig_params['time'] && Time.at(facebook_sig_params['time'].to_f) < earliest_valid_session
        true
      end
      
      def facebook_parameter_conversions
        @facebook_parameter_conversions ||= Hash.new do |hash, key| 
          lambda{|value| value}
        end.merge(
          'time' => lambda{|value| Time.at(value.to_f)},
          'in_canvas' => lambda{|value| !blank?(value)},
          'added' => lambda{|value| !blank?(value)},
          'expires' => lambda{|value| blank?(value) ? nil : Time.at(value.to_f)},
          'friends' => lambda{|value| value.split(/,/)}
        )
      end
      
      def fbml_redirect_tag(url)
        "<fb:redirect url=\"#{url_for(url)}\" />"
      end
      
      def request_comes_from_facebook?
        request_is_for_a_facebook_canvas? || request_is_facebook_ajax? || request_is_fb_ping?
      end

      def request_is_fb_ping?
        !params['fb_sig'].blank?
      end
      
      def request_is_for_a_facebook_canvas?
        !params['fb_sig_in_canvas'].blank?
      end
      
      def request_is_facebook_tab?
        !params["fb_sig_in_profile_tab"].blank?
      end
      
      def request_is_facebook_ajax?
        params["fb_sig_is_mockajax"]=="1" || params["fb_sig_is_ajax"]=="1"
      end
      def xml_http_request?
        request_is_facebook_ajax? || super
      end
      
      
      
      def application_is_installed?
        facebook_params['added']
      end
      
      def ensure_has_status_update
        has_extended_permission?("status_update") || application_needs_permission("status_update")
      end
      def ensure_has_photo_upload
        has_extended_permission?("photo_upload") || application_needs_permission("photo_upload")
      end
      def ensure_has_video_upload
        has_extended_permission?("video_upload") || application_needs_permission("video_upload")
      end
      def ensure_has_create_listing
        has_extended_permission?("create_listing") || application_needs_permission("create_listing")
      end
      
      def application_needs_permission(perm)
        redirect_to(facebook_session.permission_url(perm))
      end
      
      def has_extended_permission?(perm)
        params["fb_sig_ext_perms"] and params["fb_sig_ext_perms"].include?(perm)
      end
      
      def ensure_authenticated_to_facebook
        set_facebook_session || create_new_facebook_session_and_redirect!
      end
      
      def ensure_application_is_installed_by_facebook_user
        @installation_required = true
        returning ensure_authenticated_to_facebook && application_is_installed? do |authenticated_and_installed|
           application_is_not_installed_by_facebook_user unless authenticated_and_installed
        end
      end
      
      def application_is_not_installed_by_facebook_user
        url_params = after_facebook_login_url.nil? ? {} : { :next => after_facebook_login_url }
        redirect_to session[:facebook_session].install_url(url_params)
      end
      
      def set_facebook_request_format
        if request_is_facebook_ajax?
          params[:format] = 'fbjs'
        elsif request_comes_from_facebook?
          params[:format] = 'fbml'
        end
      end
      
      def set_adapter
        Facebooker.load_adapter(params) if(params[:fb_sig_api_key])
      end

      
      module ClassMethods
        #
        # Creates a filter which reqires a user to have already authenticated to
        # Facebook before executing actions.  Accepts the same optional options hash which
        # before_filter and after_filter accept.
        def ensure_authenticated_to_facebook(options = {})
          before_filter :ensure_authenticated_to_facebook, options
        end
        
        def ensure_application_is_installed_by_facebook_user(options = {})
          before_filter :ensure_application_is_installed_by_facebook_user, options
        end
        
        def request_comes_from_facebook?
          request_is_for_a_facebook_canvas? || request_is_facebook_ajax?
        end
      end
    end
  end
end
