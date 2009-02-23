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
  
        # Render an <fb:login-button> element
        # 
        # ==== Examples
        #
        # <%= fb_login_button%>
        # => <fb:login-button></fb:login-button>
        #
        # Specifying a javascript callback
        #
        # <%= fb_login_button 'update_something();'%>
        # => <fb:login-button onlogin='update_something();'></fb:login-button>
        #
        # Adding options <em>See:</em> http://wiki.developers.facebook.com/index.php/Fb:login-button
        #
        # <%= fb_login_button 'update_something();', :size => :small, :background => :dark%>
        # => <fb:login-button background='dark' onlogin='update_something();' size='small'></fb:login-button>
        #
        def fb_login_button(*args)

          callback = args.first
          options = args.second || {}
          options.merge!(:onlogin=>callback)if callback

          content_tag("fb:login-button",nil, options)
        end
        
        def fb_unconnected_friends_count
          content_tag "fb:unconnected-friends-count",nil
        end
      end
    end
  end
end
