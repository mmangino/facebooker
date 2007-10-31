require 'facebooker/rails/controller'
require 'facebooker/rails/facebook_url_rewriting'
module ::ActionController
  class Base
    include Facebooker::Rails::UrlRewriter
#   include Facebooker::Rails::Controller
  end
  class AbstractRequest                         
    def relative_url_root                       
      "/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']}" 
    end                                         
  end                                           
end
ActionController::Base.helper Facebooker::Rails::Helpers
