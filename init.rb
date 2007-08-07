# Yes, sad.  This is to support Facebooker as a Rails plugin.
require 'facebooker/rails/controller'
module ActionController
  class Base
    include Facebooker::Rails::Controller
  end
end