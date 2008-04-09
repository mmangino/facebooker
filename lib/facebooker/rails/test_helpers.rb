module Facebooker
  module Rails
    module TestHelpers
      def assert_fb_redirect_to(url)
        assert_response :success
        assert_not_nil facebook_redirect_url
        assert_equal url, facebook_redirect_url
      end
      
      def facebook_post(path, params={})
        params = default_facebook_parameters.update(params)
        params.merge!(:fb_sig => generate_signature(facebook_params(params).stringify_keys))

        params = params.update(:canvas => true).update(params)
        post path, params
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
        match = response.body.match(/<fb:redirect url="([^"]+)"/)
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
        