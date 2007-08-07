require 'facebooker/rails/controller'
module ::ActionController
  class Base
    include Facebooker::Rails::Controller
  end
end