module Facebooker
  module Rails
    module Helpers
      module StreamPublish
        def stream_publish(js_method,stream_post,user_message_prompt=nil,callback=nil,auto_publish=false,actor=nil)
           defaulted_callback = callback || "null"
           update_page do |page|
             page.call(js_method,
                         stream_post.user_message,
                         stream_post.attachment.to_hash,
                         stream_post.action_links,
                         Facebooker::User.cast_to_facebook_id(stream_post.target),
                         user_message_prompt,
                         page.literal(defaulted_callback),
                         auto_publish,
                         Facebooker::User.cast_to_facebook_id(actor))
           end          
        end
      end
    end
  end
end