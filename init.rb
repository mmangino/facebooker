require 'facebooker/rails/controller'
require 'ruby-debug'
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
    
    def link_to_canvas?(params)
      #yes, we do really want to see if it is false. nil means use the default action
      canvas = params.delete(:canvas)
      return false  if canvas == false 
      canvas || params[:fb_sig_in_canvas] == "1"
    end
    
    def rewrite_url_with_facebooker(*args)
      if args.first.is_a?(Hash)
        options=args.first
      else
        options = args.last
      end
      if !options.has_key?(:host) && link_to_canvas?(@request.request_parameters)
        options[:host] = "apps.facebook.com"
      end
      rewrite_url_without_facebooker(*args)
    end
    
    alias_method_chain :rewrite_url, :facebooker
  end
end
require 'facebooker/rails/facebook_session_handling'