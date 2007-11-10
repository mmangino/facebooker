require 'facebooker/rails/controller'
module ::ActionController
  class Base
    def self.inherited_with_facebooker(subclass)
      inherited_without_facebooker(subclass)
      if subclass.to_s == "ApplicationController"
        subclass.send(:include,Facebooker::Rails::Controller) 
        subclass.helper Facebooker::Rails::Helpers
      end
    end
    class << self
      alias_method_chain :inherited, :facebooker
    end

  end
  
  class AbstractRequest                         
    def relative_url_root                       
      "/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']}" 
    end                                         
  end                                           
  class UrlRewriter
    alias :rewrite_url_aliased_by_facebooker :rewrite_url
    def rewrite_url(options)
      options[:host] = "apps.facebook.com" if !options.has_key?(:host) && @request.request_parameters['fb_sig_in_canvas'] == "1"
      rewrite_url_aliased_by_facebooker(options)
    end
  end
end
require 'facbooker/rails/facebook_session_handling'