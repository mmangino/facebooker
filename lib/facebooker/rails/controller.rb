require 'facebooker'
require 'facebooker/rails/profile_publisher_extensions'
module Facebooker
  module Rails
    module Controller
      include Facebooker::Rails::ProfilePublisherExtensions
      def self.included(controller)
        controller.extend(ClassMethods)
        controller.before_filter :set_adapter
        controller.before_filter :set_fbml_format
        controller.helper_attr :facebook_session_parameters
        controller.helper_method :request_comes_from_facebook?
      end

    
      def facebook_session
        @facebook_session
      end
      
      def facebook_session_parameters
        {:fb_sig_session_key=>params[:fb_sig_session_key]}
      end
      
      
      def set_facebook_session
        
        returning session_set = session_already_secured? ||  secure_with_facebook_params! ||secure_with_token!  do
          if session_set
            capture_facebook_friends_if_available! 
            Session.current = facebook_session
          end
        end
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
            
      def secure_with_token!
        if params['auth_token']
          @facebook_session = new_facebook_session
          @facebook_session.auth_token = params['auth_token']
          @facebook_session.secure!
          session[:facebook_session] = @facebook_session
        end
      end
      
      def secure_with_facebook_params!
        return unless request_comes_from_facebook?
        
        if ['user', 'session_key'].all? {|element| facebook_params[element]}
          @facebook_session = new_facebook_session
          @facebook_session.secure_with!(facebook_params['session_key'], facebook_params['user'], facebook_params['expires'])
          session[:facebook_session] = @facebook_session
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
        raise Facebooker::Session::SignatureTooOld if Time.at(facebook_sig_params['time'].to_f) < earliest_valid_session
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
        request_is_for_a_facebook_canvas? || request_is_facebook_ajax?
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
        redirect_to session[:facebook_session].install_url
      end
      
      def set_fbml_format
        params[:format]="fbml" if request_comes_from_facebook?
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
      end
    end
  end
end