require 'facebooker/rails/cucumber/world'
require 'facebooker/mock/session'
require 'facebooker/mock/service'

Facebooker::MockService.fixture_path = File.join(RAILS_ROOT, 'features', 'support', 'facebook')

module Facebooker
  class << self
    # prevent Facebooker from adding canvas name as prefix to URLs
    def request_for_canvas(arg)
      yield
    end
  end
  
  module Rails
    module Controller
      # prevent Facebooker from rendering fb:redirect
      def redirect_to(*args)
        super
      end
      
      # Return the mock session
      def new_facebook_session
        Facebooker::MockSession.create
      end
    end
  end
end
