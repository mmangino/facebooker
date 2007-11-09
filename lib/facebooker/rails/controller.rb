require 'facebooker'
module Facebooker
  module Rails
    module Controller
      def self.included(controller)
        controller.extend(ClassMethods)
        controller.before_filter :set_fbml_format
      end
      
      def facebook_session
        @facebook_session
      end
      
      def set_facebook_session
        returning session_set = session_already_secured? || secure_with_token! || secure_with_facebook_params! || create_new_facebook_session_and_redirect! do
          capture_facebook_friends_if_available! if session_set
        end
      end
      
      def facebook_params
        @facebook_params ||= facebook_sig_params.inject(HashWithIndifferentAccess.new) do |new_hash, pair| 
                                 new_key_name = pair.first.to_s.sub(/^fb_sig_/, '')
                                 new_hash[new_key_name] = facebook_parameter_conversions[new_key_name].call(pair.last)
                                 new_hash
                             end
      end      
      
      private
      
      def session_already_secured?
        (@facebook_session = session[:facebook_session]) && session[:facebook_session].secured?
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
        if ['user', 'session_key'].all? {|element| facebook_params[element]}
          @facebook_session = new_facebook_session
          @facebook_session.secure_with!(facebook_params['session_key'], facebook_params['user'], facebook_params['expires'])
          session[:facebook_session] = @facebook_session
        end
      end
      
      def create_new_facebook_session_and_redirect!
        session[:facebook_session] = new_facebook_session
        redirect_to session[:facebook_session].login_url unless @installation_required
        false
      end
      
      def new_facebook_session
        Facebooker::Session.create(Facebooker::Session.api_key, Facebooker::Session.secret_key)
      end
      
      def capture_facebook_friends_if_available!
        if friends = facebook_params['friends']
          facebook_session.user.friends = friends.map do |friend_uid|
            User.new(friend_uid, facebook_session)
          end
        end
      end
            
      def facebook_sig_params
        params.select{|key, value| key.to_s =~ /^fb_sig/}
      end
      
      def blank?(value)
        (value == '0' || value.nil? || value == '')        
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
      
      def redirect_to(*args)
        if request_is_for_a_facebook_canvas?
          render :text => fbml_redirect_tag(*args)
        else
          super
        end
      end
      
      def fbml_redirect_tag(url)
        "<fb:redirect url=\"#{url_for(url)}\" />"
      end
      
      def request_is_for_a_facebook_canvas?
        facebook_params['in_canvas']
      end
      
      def application_is_installed?
        facebook_params['added']
      end
      
      def ensure_authenticated_to_facebook
        set_facebook_session
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
        params[:format]="fbml" if facebook_params['in_canvas']
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