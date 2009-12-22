module Facebooker
  module Rails
    module TestHelpers
      def assert_facebook_redirect_to(url)
        assert_response :success
        assert_not_nil facebook_redirect_url
        assert_equal url, facebook_redirect_url
      end

      def follow_facebook_redirect!
        facebook_post facebook_redirect_url
      end
      
      def facebook_get(path, params={}, session=nil, flash=nil)
        facebook_verb(:get, path, params, session, flash)
      end
      
      def facebook_post(path,params={}, session=nil, flash=nil)
        facebook_verb(:post, path, params, session, flash)
      end
      
      def facebook_put(path,params={}, session=nil, flash=nil)
        facebook_verb(:put, path, params, session, flash)
      end
      
      def facebook_delete(path,params={}, session=nil, flash=nil)
        facebook_verb(:delete, path, params, session, flash)
      end
      
      def facebook_verb(verb, path, params={}, session=nil, flash=nil)
        send verb, path, facebook_params(params).reverse_merge(:canvas => true), session, flash
      end
      
      def facebook_params(params = {})
        params = default_facebook_parameters.with_indifferent_access.merge(params || {})
        sig = generate_signature params
        params.merge(:fb_sig => sig)
      end

    private

      def default_facebook_parameters
        {
          :fb_sig_added => "1", 
          :fb_sig_session_key => "facebook_session_key", 
          :fb_sig_user => "1234", 
          :fb_sig_expires => "0",
          :fb_sig_in_canvas => "1",
          :fb_sig_time => Time.now.to_f
        }
      end

      def facebook_redirect_url
        match = @response.body.match(/<fb:redirect url="([^"]+)"/)
        match.nil? ? nil : match.captures[0]
      end

      def generate_signature(params)
        facebook_params = params.select { |param,_| param =~ /^fb_sig_/ }.map do |param, value|
          [param.sub(/^fb_sig_/, ''), value].join('=')
        end
        Digest::MD5.hexdigest([facebook_params.sort.join, Facebooker::Session.secret_key].join)
      end
      
    end
  end
end
        