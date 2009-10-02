require 'facebooker'
require 'facebooker/rails/profile_publisher_extensions'
module Facebooker
  module Rails
    module Controller
      include Facebooker::Rails::BackwardsCompatibleParamChecks
      include Facebooker::Rails::ProfilePublisherExtensions
      def self.included(controller)
        controller.extend(ClassMethods)
        controller.before_filter :set_facebook_request_format
        controller.helper_attr :facebook_session_parameters
        controller.helper_method :request_comes_from_facebook?
      end

      def initialize *args
        @facebook_session       = nil
        @installation_required  = nil
        super
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
      
      #this is used to proxy a connection through a rails app so the facebook secret key is not needed
      #iphone apps use this
      def create_facebook_session_with_secret
        secure_with_session_secret!
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
      
      # Redirects the top window to the given url if the content is in an iframe, otherwise performs
      # a normal redirect_to call.
      def top_redirect_to(*args)
        if request_is_facebook_iframe?
          @redirect_url = url_for(*args)
          render :layout => false, :inline => <<-HTML
            <html><head>
              <script type="text/javascript">  
                window.top.location.href = <%= @redirect_url.to_json -%>;
              </script>
              <noscript>
                <meta http-equiv="refresh" content="0;url=<%=h @redirect_url %>" />
                <meta http-equiv="window-target" content="_top" />
              </noscript>                
            </head></html>
          HTML
        else
          redirect_to(*args)
        end
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
        fb_cookie_names = cookies.keys.select{|k| k && k.starts_with?(fb_cookie_prefix)}
      end

      def secure_with_cookies!
          parsed = {}
          
          fb_cookie_names.each { |key| parsed[key[fb_cookie_prefix.size,key.size]] = cookies[key] }
 
          #returning gracefully if the cookies aren't set or have expired
          return unless parsed['session_key'] && parsed['user'] && parsed['expires'] && parsed['ss'] 
          return unless Time.at(parsed['expires'].to_s.to_f) > Time.now || (parsed['expires'] == "0")          
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
    
      def secure_with_session_secret!
        if params['auth_token']
          @facebook_session = new_facebook_session
          @facebook_session.auth_token = params['auth_token']
          @facebook_session.secure_with_session_secret!
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

      def default_after_facebook_login_url
        omit_keys = ["_method", "format"]
        options = (params||{}).clone 
        options = options.reject{|k,v| k.to_s.match(/^fb_sig/) or omit_keys.include?(k.to_s)} 
        options = options.merge({:only_path => false})
        url_for(options)
      end
      
      def create_new_facebook_session_and_redirect!
        session[:facebook_session] = new_facebook_session
        next_url = after_facebook_login_url || default_after_facebook_login_url
        top_redirect_to session[:facebook_session].login_url({:next => next_url, :canvas=>params[:fb_sig_in_canvas]}) unless @installation_required
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
        # Don't verify the signature if rack has already done so.
        unless ::Rails.version >= "2.3" and ActionController::Dispatcher.middleware.include? Rack::Facebook
          raw_string = facebook_sig_params.map{ |*args| args.join('=') }.sort.join
          actual_sig = Digest::MD5.hexdigest([raw_string, Facebooker::Session.secret_key].join)
          raise Facebooker::Session::IncorrectSignature if actual_sig != expected_signature
        end
        raise Facebooker::Session::SignatureTooOld if facebook_sig_params['time'] && Time.at(facebook_sig_params['time'].to_f) < earliest_valid_session
        true
      end
      
      def facebook_parameter_conversions
        @facebook_parameter_conversions ||= Hash.new do |hash, key| 
          lambda{|value| value}
        end.merge(
          'time'      => lambda{|value| Time.at(value.to_f)},
          'in_canvas' => lambda{|value| one_or_true(value)},
          'added'     => lambda{|value| one_or_true(value)},
          'expires'   => lambda{|value| zero_or_false(value) ? nil : Time.at(value.to_f)},
          'friends'   => lambda{|value| value.split(/,/)}
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
      
      def request_is_facebook_iframe?
        !params["fb_sig_in_iframe"].blank?
      end
      
      def request_is_facebook_ajax?
        one_or_true(params["fb_sig_is_mockajax"]) || one_or_true(params["fb_sig_is_ajax"])
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
      def ensure_has_create_event
        has_extended_permission?("create_event") || application_needs_permission("create_event")
      end
      
      def application_needs_permission(perm)
        top_redirect_to(facebook_session.permission_url(perm))
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
        next_url = after_facebook_login_url || default_after_facebook_login_url
        top_redirect_to session[:facebook_session].install_url({:next => next_url})
      end
      
      def set_facebook_request_format
        if request_is_facebook_ajax?
          request.format = :fbjs
        elsif request_comes_from_facebook? && !request_is_facebook_iframe?
          request.format = :fbml
        end
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
