module Facebooker
  module Rails
    module Helpers
      def multi_friend_request(type,message,url,&block)
        content = capture(&block)  	
        concat(content_tag("fb:request_form", 
                            multi_friend_selector(message),
                            {:action=>url,:method=>"post",:invite=>true,:type=>type,:content=>content}
                            ),
              block.binding)
      end

      def multi_friend_selector(message)
        tag("fb:multi-friend-selector",:showborder=>false,:actiontext=>message,:max=>20)
      end

      def fb_req_choice(message,url)
        tag "fb:req_choice",:label=>message,:url=>url
      end
      
     def facebook_form_for(object_name, *args, &proc)
        raise ArgumentError, "Missing block" unless block_given?
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:builder] ||= Facebooker::Rails::FacebookFormBuilder

        concat(tag("fb:editor",{:action=>url_for(options.delete(:url) || {})},true) , proc.binding)
        fields_for(object_name, *(args << options), &proc)
        concat("</fb:editor>",proc.binding)
      end
      
      def name(user,options={})
        tag "fb:name",options.merge({:uid=>user})
      end
      
      def facebook_image_tag(name,options={})
        tag "img",:src=>"http://#{ENV['FACEBOOKER_STATIC_HOST']}#{image_path(name)}"
      end
      
      def profile_pic(user,options={})
        tag "fb:profile-pic",options.merge(:uid=>user)
      end
      
      def wall(&proc)
        content = capture(&proc)  	
        concat(content_tag("fb:wall",content,{}),proc.binding)
      end
      
      def wall_post(user,message)
        content_tag("fb:wallpost",message,:uid=>user)
      end
      
      def facebook_messages
        message=""
        unless flash[:notice].blank?
          message += content_tag("fb:message",flash[:notice])
        end
        unless flash[:error].blank?
          message += content_tag("fb:error",flash[:error])
        end
        message
      end
    end
  end
end