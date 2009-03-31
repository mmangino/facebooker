require 'rack/facebook'
ActionController::Dispatcher.middleware.insert_after 'ActionController::RewindableInput',Rack::Facebook, Facebooker.secret_key