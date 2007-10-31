require 'facebooker'
module Facebooker
  module Rails
    module UrlRewriter
      alias :rewrite_url_aliased_by_facebooker :rewrite_url
      def rewrite_url(options)
        options[:host] = "apps.facebook.com" if !options.has_key?(:host) && @request.request_parameters['fb_sig_in_canvas'] == "1"
        rewrite_url_aliased_by_facebooker(options)
      end
    end
  end
end


