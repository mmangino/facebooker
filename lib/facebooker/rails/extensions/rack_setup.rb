require 'rack/facebook'
ActionController::Dispatcher.middleware.insert_after 'ActionController::Failsafe',Rack::Facebook, Facebooker.secret_key