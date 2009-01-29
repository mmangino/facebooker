module Facebooker
  module Rails
    module Helpers
      module FbConnect
        
        def fb_connect_javascript_tag
          if request.ssl?
            javascript_include_tag "https://www.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php"
          else
            javascript_include_tag "http://static.ak.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php"
          end
        end
        
        def init_fb_connect(*required_features)
          init_string = "FB.Facebook.init('#{Facebooker.api_key}','/xd_receiver.html');"
          unless required_features.blank?
             init_string = <<-FBML
              Element.observe(window,'load', function() {
                FB_RequireFeatures(#{required_features.to_json}, function() {
                  #{init_string}
                });
              });
              FBML
          end
          javascript_tag init_string
        end
        
        def fb_login_button(callback=nil)
          content_tag("fb:login-button",nil,(callback.nil? ? {} : {:onlogin=>callback}))
        end
        
        def fb_unconnected_friends_count
          content_tag "fb:unconnected-friends-count",nil
        end
      end
    end
  end
end
