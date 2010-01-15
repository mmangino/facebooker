# Somewhere in 2.3 RewindableInput was removed- rack supports it natively
require 'rack/facebook'
require 'rack/facebook_session'

ActionController::Dispatcher.middleware.insert_before( 
  ActionController::ParamsParser,
  Rack::Facebook
)

# ActionController::Dispatcher.middleware.insert_before(
#   ActionController::Base.session_store,
#   Rack::FacebookSession,
#   lambda { ActionController::Base.session_options[:key] }
# )