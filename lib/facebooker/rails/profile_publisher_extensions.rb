module Facebooker
  module Rails
    module ProfilePublisherExtensions

      ##
      # returns true if Facebook is requesting the interface for a profile publisher
      def wants_interface?
        params[:method] == "publisher_getInterface"
      end

      ##
      # render the interface for a publisher. 
      # fbml is the content in string form. Use render_to_string to get the content from a template
      # publish_enabled controlls whether the post form is active by default. If it isn't, you'll need to use fbjs to activate it
      # comment_enabled controls whether to include a comment box
      def render_publisher_interface(fbml,publish_enabled=true,comment_enabled=false)
        render :json=>{:content=>{:fbml=>fbml,:publishEnabled=>publish_enabled,:commentEnabled=>comment_enabled},
         :method=>"publisher_getInterface"}
      end
      
      # render an error while publishing the template
      # This can be used for validation errors
      def render_publisher_error(title,body)
        render :json=>{:errorCode=>1,:errorTitle=>title,:errorMessage=>body}.to_json
      end

      # render the response for a feed. This takes a user_action object like those returned from the Rails Publisher
      # For instance, AttackPublisher.create_attack(@attack)
      # The template must have been registered previously
      def render_publisher_response(user_action)
        render :json=>{:content=> {
            :feed=>{
              :template_id=>user_action.template_id,
              :template_data=>user_action.data
            }
          },
          :method=>"publisher_getFeedStory"
        }
      end
    end
  end
end