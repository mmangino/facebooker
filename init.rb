require 'facebooker/rails/controller'
# module ::ActionController
#   class Base
#     include Facebooker::Rails::Controller
#   end
# end
ActionController::Base.helper Facebooker::Rails::Helpers
