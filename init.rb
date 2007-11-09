require 'facebooker/rails/controller'
require 'facebooker/rails/facebook_url_rewriting'
module ::ActionController
  class Base
    include Facebooker::Rails::UrlRewriter
    def self.inherited(subclass)
      super
      subclass.send(:include,Facebooker::Rails::Controller) if subclass.to_s == "ApplicationController"
    end
  end
  class AbstractRequest                         
    def relative_url_root                       
      "/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']}" 
    end                                         
  end                                           
end
ActionController::Base.helper Facebooker::Rails::Helpers
