module ::ActionController
  class AbstractRequest                         
    def relative_url_root                       
      "/#{ENV['FACEBOOKER_RELATIVE_URL_ROOT']}" 
    end                                         
  end
  
  class UrlRewriter
    RESERVED_OPTIONS << :canvas
  
    def link_to_canvas?(params, options)
      option_override = options[:canvas]
      return false if option_override == false # important to check for false. nil should use default behavior
      option_override || params["fb_sig_in_canvas"] == "1" ||  params[:fb_sig_in_canvas] == "1"
    end
  
    def rewrite_url_with_facebooker(*args)
      options = args.first.is_a?(Hash) ? args.first : args.last
      options[:skip_relative_url_root] ||= !link_to_canvas?(@request.request_parameters, options)
      if link_to_canvas?(@request.request_parameters, options) && !options.has_key?(:host)
        options[:host] = "apps.facebook.com"
      end 
      options.delete(:canvas)
      rewrite_url_without_facebooker(*args)
    end
  
    alias_method_chain :rewrite_url, :facebooker
  end
end