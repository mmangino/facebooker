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
      def fb_multi_friend_selector(message,options={},&block)
        tag("fb:multi-friend-selector",options.merge(:showborder=>false,:actiontext=>message,:max=>20))
      end
      # Render an <fb:multi-friend-selector> with the passed in welcome message
      def fb_multi_friend_selector_condensed(options={},&block)
        tag("fb:multi-friend-selector",options.merge(:condensed=>true))
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
     def facebook_form_for( record_or_name_or_array,*args, &proc)

       raise ArgumentError, "Missing block" unless block_given?
       options = args.last.is_a?(Hash) ? args.pop : {}

       case record_or_name_or_array
       when String, Symbol
         object_name = record_or_name_or_array
       when Array
         object = record_or_name_or_array.last
         object_name = ActionController::RecordIdentifier.singular_class_name(object)
         apply_form_for_options!(record_or_name_or_array, options)
         args.unshift object
       else
         object = record_or_name_or_array
         object_name = ActionController::RecordIdentifier.singular_class_name(object)
         apply_form_for_options!([object], options)
         args.unshift object
       end
        method = (options[:html]||{})[:method]
        options[:builder] ||= Facebooker::Rails::FacebookFormBuilder
        editor_options={}
        
        action=options.delete(:url)
        editor_options[:action]= action unless action.blank?
        width=options.delete(:width)
        editor_options[:width]=width unless width.blank?
        width=options.delete(:labelwidth)
        editor_options[:labelwidth]=width unless width.blank?

        concat(tag("fb:editor",editor_options,true) , proc.binding)
        concat(tag(:input,{:type=>"hidden",:name=>:_method, :value=>method},false), proc.binding) unless method.blank?
        fields_for( object_name,*(args << options), &proc)
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
      FB_PRONOUN_VALID_OPTION_KEYS = [:useyou, :possessive, :reflexive, :objective, 
                                      :usethey, :capitalize]


      def fb_ref(options)
        options.assert_valid_keys(FB_REF_VALID_OPTION_KEYS)
        validate_fb_ref_has_either_url_or_handle(options)
        validate_fb_ref_does_not_have_both_url_and_handle(options)
        tag("fb:ref", options)
      end
      
      def validate_fb_ref_has_either_url_or_handle(options)
        unless options.has_key?(:url) || options.has_key?(:handle)
          raise ArgumentError, "fb_ref requires :url or :handle"
        end
      end
      
      def validate_fb_ref_does_not_have_both_url_and_handle(options)
        if options.has_key?(:url) && options.has_key?(:handle)
          raise ArgumentError, "fb_ref may not have both :url and :handle"
        end
      end
      
      FB_REF_VALID_OPTION_KEYS = [:url, :handle]
      
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
      
      
      def fb_photo(photo, options={})
        options.assert_valid_keys(FB_PHOTO_VALID_OPTION_KEYS)
        options.merge!(:pid => cast_to_photo_id(photo))
        validate_fb_photo_size(options)
        validate_fb_photo_align_value(options)
        tag("fb:photo", options)
      end

      FB_PHOTO_VALID_OPTION_KEYS = [:uid, :size, :align]

      def cast_to_photo_id(object)
        object.respond_to?(:photo_id) ? object.photo_id : object
      end
      
      VALID_FB_SHARED_PHOTO_SIZES = [:thumb, :small, :normal, :square]
      VALID_FB_PHOTO_SIZES = VALID_FB_SHARED_PHOTO_SIZES      
      VALID_FB_PROFILE_PIC_SIZES = VALID_FB_SHARED_PHOTO_SIZES
      
      # Deprecated
      #
      # set ActionController::Base.asset_host and use the regular image_tag method.      
      def facebook_image_tag(name,options={})
        tag "img",:src=>"http://#{ENV['FACEBOOKER_STATIC_HOST']}#{image_path(name)}"
      end
      
      
      def fb_tabs(&block)
        content = capture(&block)  	
        concat(content_tag("fb:tabs", content), block.binding)
      end
      
      def fb_tab_item(title, url, options={})
        options.assert_valid_keys(FB_TAB_ITEM_VALID_OPTION_KEYS)
        options.merge!(:title => title, :href => url)  	
        validate_fb_tab_item_align_value(options)
        tag("fb:tab-item", options)
      end

      FB_TAB_ITEM_VALID_OPTION_KEYS = [:align, :selected]

      def validate_fb_tab_item_align_value(options)
        if options.has_key?(:align) && !VALID_FB_TAB_ITEM_ALIGN_VALUES.include?(options[:align].to_sym)
          raise(ArgumentError, "Unkown value for align: #{options[:align]}")
        end
      end
      
      def validate_fb_photo_align_value(options)
        if options.has_key?(:align) && !VALID_FB_PHOTO_ALIGN_VALUES.include?(options[:align].to_sym)
          raise(ArgumentError, "Unkown value for align: #{options[:align]}")
        end
      end
      
      VALID_FB_SHARED_ALIGN_VALUES = [:left, :right]
      VALID_FB_PHOTO_ALIGN_VALUES = VALID_FB_SHARED_ALIGN_VALUES
      VALID_FB_TAB_ITEM_ALIGN_VALUES = VALID_FB_SHARED_ALIGN_VALUES
      
      
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
      def fb_wallpost(user,message)
        content_tag("fb:wallpost",message,:uid=>cast_to_facebook_id(user))
      end
      alias_method :fb_wall_post, :fb_wallpost
      
      def fb_error(message, text=nil)
        fb_status_msg("error", message, text)
      end
      
      def fb_explanation(message, text=nil)
        fb_status_msg("explanation", message, text)
      end

      def fb_success(message, text=nil)
        fb_status_msg("success", message, text)
      end
      
      # Render flash values as <fb:message> and <fb:error> tags
      #
      # values in flash[:notice] will be rendered as an <fb:message>
      #
      # values in flash[:error] will be rednered as an <fb:error>
      def facebook_messages
        message=""
        unless flash[:notice].blank?
          message += fb_success(flash[:notice])
        end
        unless flash[:error].blank?
          message += fb_error(flash[:error])
        end
        message
      end
      
      # Create a dashboard. It can contain fb_action, fb_help, and fb_create_button
      #
      # For Example:
      #   <% fb_dashboard do %>
      #     <%= APP_NAME %>
      #     <%= fb_action 'My Matches', search_path %>
      #     <%= fb_help 'Feedback', "http://www.facebook.com/apps/application.php?id=6236036681" %>
      #     <%= fb_create_button 'Invite Friends', main_path %>
      #   <% end %>
      def fb_dashboard(&proc)
        content = capture(&proc)  	
        concat(content_tag("fb:dashboard",content,{}),proc.binding)
      end

      # Renders an action using the <fb:action> tag
      def fb_action(name, url)
        "<fb:action href=\"#{url_for(url)}\">#{name}</fb:action>"
      end
           
      # Render a <fb:help> tag
      # For use inside <fb:dashboard>
      def fb_help(name, url)
        "<fb:help href=\"#{url_for(url)}\">#{name}</fb:help>"
      end

      # Render a <fb:create-button> tag
      # For use inside <fb:dashboard>
			def fb_create_button(name, url)
			 	"<fb:create-button href=\"#{url_for(url)}\">#{name}</fb:create-button>"
			end
			
			# Create a comment area
			def fb_comments(xid,canpost=true,candelete=false,numposts=5,options={})
			  tag "fb:comments",options.merge(:xid=>xid,:canpost=>canpost.to_s,:candelete=>candelete.to_s,:numposts=>numposts)
			end
      
      def fb_if_is_app_user(user,options={},&proc)
        content = capture(&proc) 
        concat(content_tag("fb:if-is-app-user",content,options.merge(:uid=>cast_to_facebook_id(user))),proc.binding)
      end
      
      def fb_if_is_user(user,&proc)
        content = capture(&proc) 
        user = [user] unless user.is_a? Array
        user_list=user.map{|u| cast_to_facebook_id(u)}.join(",")
        concat(content_tag("fb:if-is-user",content,{:uid=>user_list}),proc.binding)
      end
      
      def fb_else
        content = capture(&proc) 
        concat(content_tag("fb:else",content),proc.binding)
      end
      
      def fb_about_url
        "http://www.facebook.com/apps/application.php?api_key=#{ENV["FACEBOOK_API_KEY"]}"
      end
      
      protected
      
      def cast_to_facebook_id(object)
        Facebooker::User.cast_to_facebook_id(object)
      end
      
      def validate_fb_profile_pic_size(options)
        if options.has_key?(:size) && !VALID_FB_PROFILE_PIC_SIZES.include?(options[:size].to_sym)
          raise(ArgumentError, "Unkown value for size: #{options[:size]}")
        end
      end

      def validate_fb_photo_size(options)
        if options.has_key?(:size) && !VALID_FB_PHOTO_SIZES.include?(options[:size].to_sym)
          raise(ArgumentError, "Unkown value for size: #{options[:size]}")
        end
      end
      
      private
      
      def fb_status_msg(type, message, text)
        if text.blank?
          tag("fb:#{type}", :message => message)
        else
          content_tag("fb:#{type}", content_tag("fb:message", message) + text)
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