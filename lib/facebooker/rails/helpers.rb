module Facebooker
  module Rails
    
    # Facebook specific helpers for creating FBML
    # 
    # All helpers that take a user as a parameter will get the Facebook UID from the facebook_id attribute if it exists.
    # It will use to_s if the facebook_id attribute is not present.
    #
    module Helpers
      
      # Create an fb:request-form without a selector
      #
      # The block passed to this tag is used as the content of the form
      #
      # The message param is the name sent to content_for that specifies the body of the message
      #
      # For example,
      #
      #  <% content_for("invite_message") do %>
      #    This gets sent in the invite. <%= fb_req_choice("with a button!",new_poke_path) %>
      #  <% end %>
      #  <% fb_request_form("Poke","invite_message",create_poke_path) do %>
      #    Send a poke to: <%= fb_friend_selector %> <br />
      #    <%= fb_request_form_submit %>
      #  <% end %>
      def fb_request_form(type,message_param,url,&block)
        content = capture(&block)
        message = @template.instance_variable_get("@content_for_#{message_param}") 
        concat(content_tag("fb:request-form", content,
                  {:action=>url,:method=>"post",:invite=>true,:type=>type,:content=>message}),
              block.binding)
      end
      
      # Create a submit button for an <fb:request-form>
      def fb_request_form_submit
        tag "fb:request-form-submit"
      end
      
      # Create an fb:request-form with an fb_multi_friend_selector inside
      # 
      # The content of the block are used as the message on the form,
      #
      # For example:
      #  <% fb_multi_friend_request("Poke","Choose some friends to Poke",create_poke_path) do %>
      #    If you select some friends, they will see this message.
      #    <%= fb_req_choice("They will get this button, too",new_poke_path) %>
      #  <% end %>
      def fb_multi_friend_request(type,friend_selector_message,url,&block)
        content = capture(&block)  	
        concat(content_tag("fb:request-form", 
                            fb_multi_friend_selector(friend_selector_message),
                            {:action=>url,:method=>"post",:invite=>true,:type=>type,:content=>content}
                            ),
              block.binding)
      end
      
      # Render an <fb:friend-selector> element
      #
      def fb_friend_selector(options={})
        tag("fb:friend-selector",options)
      end
      
      # Render an <fb:multi-friend-input> element
      def fb_multi_friend_input(options={})
        tag "fb:multi-friend-input",options
      end

      # Render an <fb:multi-friend-selector> with the passed in welcome message
      def fb_multi_friend_selector(message,&block)
        tag("fb:multi-friend-selector",:showborder=>false,:actiontext=>message,:max=>20)
      end

      # Render a button in a request using the <fb:req-choice> tag
      #
      # This should be used inside the block of an fb_multi_friend_request of a
      def fb_req_choice(label,url)
        tag "fb:req-choice",:label=>label,:url=>url
      end
     
     # Create a facebook form using <fb:editor>
     #
     # It yields a form builder that will convert the standard rails form helpers 
     # into the facebook specific version. 
     #
     # Example:
     #  <% facebook_form_for(:poke,@poke,:url => create_poke_path) do |f| %>
     #    <%= f.text_field :message, :label=>"message" %>
     #    <%= f.buttons "Save Poke" %>
     #  <% end %>
     #
     #  will generate
     #
     #  <fb:editor action="/pokes/create">
     #    <fb:editor-text name="poke[message]" id="poke_message" value="" label="message" />
     #    <fb:editor-buttonset>
     #     <fb:editor-button label="Save Poke"
     #    </fb:editor-buttonset>
     #  </fb:editor>
     def facebook_form_for(object_name, *args, &proc)
        raise ArgumentError, "Missing block" unless block_given?
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:builder] ||= Facebooker::Rails::FacebookFormBuilder

        concat(tag("fb:editor",{:action=>url_for(options.delete(:url) || {})},true) , proc.binding)
        fields_for(object_name, *(args << options), &proc)
        concat("</fb:editor>",proc.binding)
      end
      
      # Render an fb:name tag for the given user
      #
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
            
      # Render an <fb:pronoun> tag for the specified user
      #      
      def fb_pronoun(user, options={})
        options.transform_keys!(FB_PRONOUN_OPTION_KEYS_TO_TRANSFORM)
        options.assert_valid_keys(FB_PRONOUN_VALID_OPTION_KEYS)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:pronoun", options)
      end
      
      FB_PRONOUN_OPTION_KEYS_TO_TRANSFORM = {:use_you => :useyou, :use_they => :usethey}
      FB_PRONOUN_VALID_OPTION_KEYS = [:useyou, :possssive, :reflexive, :objective, 
                                      :usethey, :capitalize]

      
      # Render an <fb:profile-pic> for the specified user.
      #
      # You can optionally specify the size using the :size=> option.
      #
      # Valid sizes are :thumb, :small, :normal and :square
      def fb_profile_pic(user, options={})
        validate_fb_profile_pic_size(options)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:profile-pic", options)
      end
      
      
      VALID_FB_PROFILE_PIC_SIZES = [:thumb, :small, :normal, :square]
      
      # Deprecated
      #
      # set ActionController::Base.asset_host and use the regular image_tag method.      
      def facebook_image_tag(name,options={})
        tag "img",:src=>"http://#{ENV['FACEBOOKER_STATIC_HOST']}#{image_path(name)}"
      end
      
      
      # Create a Facebook wall. It can contain fb_wall_posts
      #
      # For Example:
      #   <% fb_wall do %>
      #     <%= fb_wall_post(@user,"This is my message") %>
      #     <%= fb_wall_post(@otheruser,"This is another message") %>
      #   <% end %>
      def fb_wall(&proc)
        content = capture(&proc)  	
        concat(content_tag("fb:wall",content,{}),proc.binding)
      end
      
      # Render an <fb:wallpost> tag
      def fb_wall_post(user,message)
        content_tag("fb:wallpost",message,:uid=>user)
      end
      alias_method :fb_wallpost, :fb_wall_post
      
      
      def fb_error(message, text=nil)
        if text.blank?
          tag("fb:error", :message => message)
        else
          content_tag("fb:error", content_tag("fb:message", message) + text)
        end
      end
      
      def fb_success(message, text=nil)
        if text.blank?
          tag("fb:success", :message => message)
        else
          content_tag("fb:success", content_tag("fb:message", message) + text)
        end
      end
      
      # Render flash values as <fb:message> and <fb:error> tags
      #
      # values in flash[:notice] will be rendered as an <fb:message>
      #
      # values in flash[:error] will be rednered as an <fb:error>
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
      
      protected
      
      def cast_to_facebook_id(object)
        if object.respond_to?(:facebook_id)
          object.facebook_id
        else
          object
        end
      end
      
      def validate_fb_profile_pic_size(options)
        if options.has_key?(:size) && !VALID_FB_PROFILE_PIC_SIZES.include?(options[:size].to_sym)
          raise(ArgumentError, "Unkown value for size: #{options[:size]}")
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