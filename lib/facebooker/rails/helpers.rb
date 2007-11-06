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
      
      def fb_name(user, options={})
        options.transform_keys!(FB_NAME_OPTION_KEYS_TO_TRANSFORM)
        options.assert_valid_keys(FB_NAME_VALID_OPTION_KEYS)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:name", options)
      end

      FB_NAME_OPTION_KEYS_TO_TRANSFORM = {:first_name_only => :firstnameonly, 
                                          :last_name_only => :lastnameonly,
                                          :show_network => :shownetwork,
                                          :use_you => :useyou,
                                          :if_cant_see => :ifcantsee,
                                          :subject_id => :subjectid}
      FB_NAME_VALID_OPTION_KEYS = [:firstnameonly, :linked, :lastnameonly, :possessive, :reflexive, 
                                   :shownetwork, :useyou, :ifcantsee, :capitalize, :subjectid]
            
      def fb_pronoun(user, options={})
        options.transform_keys!(FB_PRONOUN_OPTION_KEYS_TO_TRANSFORM)
        options.assert_valid_keys(FB_PRONOUN_VALID_OPTION_KEYS)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:pronoun", options)
      end
      
      FB_PRONOUN_OPTION_KEYS_TO_TRANSFORM = {:use_you => :useyou, :use_they => :usethey}
      FB_PRONOUN_VALID_OPTION_KEYS = [:useyou, :possssive, :reflexive, :objective, 
                                      :usethey, :capitalize]

      
      def fb_profile_pic(user, options={})
        validate_fb_profile_pic_size(options)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:profile-pic", options)
      end
      
      def validate_fb_profile_pic_size(options)
        if options.has_key?(:size) && !VALID_FB_PROFILE_PIC_SIZES.include?(options[:size].to_sym)
          raise(ArgumentError, "Unkown value for size: #{options[:size]}")
        end
      end
      
      VALID_FB_PROFILE_PIC_SIZES = [:thumb, :small, :normal, :square]
            
      def facebook_image_tag(name,options={})
        tag "img",:src=>"http://#{ENV['FACEBOOKER_STATIC_HOST']}#{image_path(name)}"
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
      
      def cast_to_facebook_id(object)
        if object.respond_to?(:facebook_id)
          object.facebook_id
        else
          object
        end
      end
    end
  end
end

class Hash
  def transform_keys!(transformation_hash)
    transformation_hash.each_pair{|key, value| transform_key!(key, value)}
  end
  
  def transform_key!(old_key, new_key)
    swapkey!(new_key, old_key)
  end
  
  ### This method is lifted from Ruby Facets core
  def swapkey!( newkey, oldkey )
    self[newkey] = self.delete(oldkey) if self.has_key?(oldkey)
    self
  end
end