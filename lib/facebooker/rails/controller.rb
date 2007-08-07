module Facebooker
  module Rails
    module Controller
      def self.included(controller)
        controller.extend(ClassMethods)
      end
      
      def facebook_session
        @facebook_session
      end
      
      def set_facebook_session
        @facebook_session = session[:facebook_session]
        if @facebook_session
          @facebook_session.secure! unless @facebook_session.secured?
        else
          @facebook_session = Facebooker::Session.create(Facebooker::Session.api_key, Facebooker::Session.secret_key)
          session[:facebook_session] = @facebook_session
          redirect_to @facebook_session.login_url
          false
        end
      end
      
      module ClassMethods
        #
        # Creates a filter which reqires a user to have already authenticated to
        # Facebook before executing actions.  Accepts the same optional options hash which
        # before_filter and after_filter accept.
        def ensure_authenticated_to_facebook(options = {})
          before_filter :set_facebook_session, options
        end
      end
    end
  end
end