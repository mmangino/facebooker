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
      
      def facebook_get(path,params={})
        facebook_verb(:get,path,params)
      end
      
      def facebook_post(path,params={})
        facebook_verb(:post,path,params)
      end
      
      def facebook_put(path,params={})
        facebook_verb(:put,path,params)
      end
      def facebook_delete(path,params={})
        facebook_verb(:delete,path,params)
      end
      
      def facebook_verb(verb,path, params={})
        params = default_facebook_parameters.update(params)
        params.merge!(:fb_sig => generate_signature(facebook_params(params).stringify_keys))

        params = params.update(:canvas => true).update(params)
        send verb, path, params
      end
      
      def facebook_post(path, params={}, fb_params=facebook_parameters)
        params = fb_params.merge(:canvas => true).merge(params)
        post path, params    
      end
      
      def facebook_parameters(overrides=nil)
        overrides ||= {}
        params = default_facebook_parameters.merge(overrides)
        params.merge(:fb_sig => generate_signature(params.stringify_keys))
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

      def facebook_params(params)
        params.inject({}) do |fb_params, pair| 
          unless pair.first.to_s.match(/^fb_sig_/).nil?
            fb_params[pair.first] = pair.last
          end
          fb_params
        end
      end

      def facebook_redirect_url
        match = @response.body.match(/<fb:redirect url="([^"]+)"/)
        match.nil? ? nil : match.captures[0]
      end

      def generate_signature(facebook_params)
        facebook_sig_params = facebook_params.inject({}) do |collection, pair|
          collection[pair.first.sub(/^fb_sig_/, '')] = pair.last
          collection
        end

        raw_string = facebook_sig_params.map{ |*args| args.join('=') }.sort.join
        Digest::MD5.hexdigest([raw_string, Facebooker::Session.secret_key].join)
      end
      
    end
  end
end
        