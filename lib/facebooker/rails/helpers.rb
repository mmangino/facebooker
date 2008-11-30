module Facebooker
  module Rails
    
    # Facebook specific helpers for creating FBML
    # 
    # All helpers that take a user as a parameter will get the Facebook UID from the facebook_id attribute if it exists.
    # It will use to_s if the facebook_id attribute is not present.
    #
    module Helpers
      
      
      # Create an fb:dialog
      # id must be a unique name e.g. "my_dialog"
      # cancel_button is true or false
      def fb_dialog( id, cancel_button, &block )
        content = capture(&block)
        concat( content_tag("fb:dialog", content, {:id => id, :cancel_button => cancel_button}), block.binding )
      end
      
      def fb_dialog_title( title )
        content_tag "fb:dialog-title", title
      end
      
      def fb_dialog_content( &block )
        content = capture(&block)  
        concat( content_tag("fb:dialog-content", content), block.binding )      
      end
      
      def fb_dialog_button( type, value, options={} )
        options.assert_valid_keys FB_DIALOG_BUTTON_VALID_OPTION_KEYS
        options.merge! :type => type, :value => value
        tag "fb:dialog-button", options
      end
      
      FB_DIALOG_BUTTON_VALID_OPTION_KEYS = [:close_dialog, :href, :form_id, :clickrewriteurl, :clickrewriteid, :clickrewriteform]
      
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
      def fb_request_form(type,message_param,url,options={},&block)
        content = capture(&block)
        message = @template.instance_variable_get("@content_for_#{message_param}") 
        concat(content_tag("fb:request-form", content + token_tag,
                  {:action=>url,:method=>"post",:invite=>true,:type=>type,:content=>message}.merge(options)),
              block.binding)
      end

			# Create a submit button for an <fb:request-form>
			# If the request is for an individual user you can optionally
			# Provide the user and a label for the request button.
			# For example
			#   <% content_for("invite_user") do %>
			#     This gets sent in the invite. <%= fb_req_choice("Come join us!",new_invite_path) %>
			#   <% end %>
			#   <% fb_request_form("Invite","invite_user",create_invite_path) do %>
			#     Invite <%= fb_name(@facebook_user.friends.first.id)%> to the party <br />
			#     <%= fb_request_form_submit(@facebook_user.friends.first.id,"Invite %n") %>
			#   <% end %>
			# <em>See:</em> http://wiki.developers.facebook.com/index.php/Fb:request-form-submit for options
			def fb_request_form_submit(options={})
			   tag("fb:request-form-submit",stringify_vals(options))
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
                            fb_multi_friend_selector(friend_selector_message) + token_tag,
                            {:action=>url,:method=>"post",:invite=>true,:type=>type,:content=>content}
                            ),
              block.binding)
      end
      
      # Render an <fb:friend-selector> element
      # <em>See:</em> http://wiki.developers.facebook.com/index.php/Fb:friend-selector for options
      #
      def fb_friend_selector(options={})
        tag("fb:friend-selector",stringify_vals(options))
      end
      
      # Render an <fb:multi-friend-input> element
      # <em> See: </em> http://wiki.developers.facebook.com/index.php/Fb:multi-friend-input for options
      def fb_multi_friend_input(options={})
        tag "fb:multi-friend-input",stringify_vals(options)
      end

      # Render an <fb:multi-friend-selector> with the passed in welcome message
      # Full version shows all profile pics for friends.  
      # <em> See: </em> http://wiki.developers.facebook.com/index.php/Fb:multi-friend-selector for options 
      # <em> Note: </em> I don't think the block is used here.
      def fb_multi_friend_selector(message,options={},&block)
        options = options.dup
        tag("fb:multi-friend-selector",stringify_vals(options.merge(:showborder=>false,:actiontext=>message,:max=>20)))
      end

      # Render a condensed <fb:multi-friend-selector> with the passed in welcome message 
      # Condensed version show checkboxes for each friend.
      # <em> See: </em> http://wiki.developers.facebook.com/index.php/Fb:multi-friend-selector_%28condensed%29 for options
      # <em> Note: </em> I don't think the block is used here.
      def fb_multi_friend_selector_condensed(options={},&block)
        options = options.dup
        tag("fb:multi-friend-selector",stringify_vals(options.merge(:condensed=>true)))
      end

      # Render a button in a request using the <fb:req-choice> tag
      # url must be an absolute url
      # This should be used inside the block of an fb_multi_friend_request  
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
        concat(token_tag, proc.binding)
        fields_for( object_name,*(args << options), &proc)
        concat("</fb:editor>",proc.binding)
      end
      
      # Render an fb:name tag for the given user
      # This renders the name of the user specified.  You can use this tag as both subject and object of 
      # a sentence.  <em> See </em> http://wiki.developers.facebook.com/index.php/Fb:name for full description.  
      # Use this tag on FBML pages instead of retrieving the user's info and rendering the name explicitly.
      #
      def fb_name(user, options={})
        options = options.dup
        options.transform_keys!(FB_NAME_OPTION_KEYS_TO_TRANSFORM)
        options.assert_valid_keys(FB_NAME_VALID_OPTION_KEYS)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:name", stringify_vals(options))
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
      # Options give flexibility for placing in any part of a sentence.
      # <em> See </em> http://wiki.developers.facebook.com/index.php/Fb:pronoun for complete list of options.
      #      
      def fb_pronoun(user, options={})
        options = options.dup
        options.transform_keys!(FB_PRONOUN_OPTION_KEYS_TO_TRANSFORM)
        options.assert_valid_keys(FB_PRONOUN_VALID_OPTION_KEYS)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:pronoun", stringify_vals(options))
      end
      
      FB_PRONOUN_OPTION_KEYS_TO_TRANSFORM = {:use_you => :useyou, :use_they => :usethey}
      FB_PRONOUN_VALID_OPTION_KEYS = [:useyou, :possessive, :reflexive, :objective, 
                                      :usethey, :capitalize]

      # Render an fb:ref tag.  
      # Options must contain either url or handle.
      # * <em> url </em> The URL from which to fetch the FBML. You may need to call fbml.refreshRefUrl to refresh cache
      # * <em> handle </em> The string previously set by fbml.setRefHandle that identifies the FBML 
      # <em> See </em> http://wiki.developers.facebook.com/index.php/Fb:ref for complete description 
      def fb_ref(options)
        options.assert_valid_keys(FB_REF_VALID_OPTION_KEYS)
        validate_fb_ref_has_either_url_or_handle(options)
        validate_fb_ref_does_not_have_both_url_and_handle(options)
        tag("fb:ref", stringify_vals(options))
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
        options = options.dup
        validate_fb_profile_pic_size(options)
        options.merge!(:uid => cast_to_facebook_id(user))
        tag("fb:profile-pic", stringify_vals(options))
      end
      
      # Render an fb:photo tag.
      # photo is either a Facebooker::Photo or an id of a Facebook photo or an object that responds to photo_id.
      # <em> See: </em> http://wiki.developers.facebook.com/index.php/Fb:photo for complete list of options.
      def fb_photo(photo, options={})
        options = options.dup
        options.assert_valid_keys(FB_PHOTO_VALID_OPTION_KEYS)
        options.merge!(:pid => cast_to_photo_id(photo))
        validate_fb_photo_size(options)
        validate_fb_photo_align_value(options)
        tag("fb:photo", stringify_vals(options))
      end

      FB_PHOTO_VALID_OPTION_KEYS = [:uid, :size, :align]

      def cast_to_photo_id(object)
        object.respond_to?(:photo_id) ? object.photo_id : object
      end
      
      VALID_FB_SHARED_PHOTO_SIZES = [:thumb, :small, :normal, :square]
      VALID_FB_PHOTO_SIZES = VALID_FB_SHARED_PHOTO_SIZES      
      VALID_FB_PROFILE_PIC_SIZES = VALID_FB_SHARED_PHOTO_SIZES
      VALID_PERMISSIONS=[:email, :offline_access, :status_update, :photo_upload, :create_listing, :create_event, :rsvp_event, :sms]
      
      # Render an fb:tabs tag containing some number of fb:tab_item tags.
      # Example:
      # <% fb_tabs do %>  
	 		 #  	   <%= fb_tab_item("Home", "home") %>  
	 		 # 			 <%= fb_tab_item("Office", "office") %>  
	 		 # <% end %>        
      def fb_tabs(&block)
        content = capture(&block)  	
        concat(content_tag("fb:tabs", content), block.binding)
      end
      
      # Render an fb:tab_item tag. 
      # Use this in conjunction with fb_tabs 
      # Options can contains :selected => true to indicate that a tab is the current tab.
      # <em> See: </em> http://wiki.developers.facebook.com/index.php/Fb:tab-item for complete list of options
      def fb_tab_item(title, url, options={})
        options= options.dup
        options.assert_valid_keys(FB_TAB_ITEM_VALID_OPTION_KEYS)
        options.merge!(:title => title, :href => url)  	
        validate_fb_tab_item_align_value(options)
        tag("fb:tab-item", stringify_vals(options))
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
      # TODO:  Optionally takes a time parameter t = int The current time, which is displayed in epoch seconds.
      def fb_wallpost(user,message)
        content_tag("fb:wallpost",message,:uid=>cast_to_facebook_id(user))
      end
      alias_method :fb_wall_post, :fb_wallpost
      
      # Render an <fb:error> tag
      # If message and text are present then this will render fb:error and fb:message tag
      # TODO: Optionally takes a decoration tag with value of 'no_padding' or 'shorten'
      def fb_error(message, text=nil)
        fb_status_msg("error", message, text)
      end
      
      # Render an <fb:explanation> tag
      # If message and text are present then this will render fb:error and fb:message tag
      # TODO: Optionally takes a decoration tag with value of 'no_padding' or 'shorten'
      def fb_explanation(message, text=nil)
        fb_status_msg("explanation", message, text)
      end

      # Render an <fb:success> tag
      # If message and text are present then this will render fb:error and fb:message tag
      # TODO: Optionally takes a decoration tag with value of 'no_padding' or 'shorten'
      def fb_success(message, text=nil)
        fb_status_msg("success", message, text)
      end
      
      # Render flash values as <fb:message> and <fb:error> tags
      #
      # values in flash[:notice] will be rendered as an <fb:message>
      #
      # values in flash[:error] will be rendered as an <fb:error>   
      # TODO: Allow flash[:info] to render fb_explanation
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
        if block_given?
          content = capture(&proc)  	
          concat(content_tag("fb:dashboard",content,{}),proc.binding)
        else
          content_tag("fb:dashboard",content,{})
        end
      end
      
      # Content for the wide profile box goes in this tag
      def fb_wide(&proc)
        content = capture(&proc)
        concat(content_tag("fb:wide", content, {}), proc.binding)
      end

      # Content for the narrow profile box goes in this tag
      def fb_narrow(&proc)
        content = capture(&proc)
        concat(content_tag("fb:narrow", content, {}), proc.binding)
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
			# All the data for this content area is stored on the facebook servers.
			# <em>See:</em> http://wiki.developers.facebook.com/index.php/Fb:comments for full details 
			def fb_comments(xid,canpost=true,candelete=false,numposts=5,options={})
			  options = options.dup
                          title = (title = options.delete(:title)) ? fb_title(title) : nil 
			  content_tag "fb:comments",title,stringify_vals(options.merge(:xid=>xid,:canpost=>canpost.to_s,:candelete=>candelete.to_s,:numposts=>numposts))
			end
			
			# Adds a title to the title bar
			#
			# Facebook | App Name | This is the canvas page window title
			#
      # +title+: This is the canvas page window 
			def fb_title(title)
			 "<fb:title>#{title}</fb:title>"
			end
      
      # Create a Google Analytics tag
      # 
      # +uacct+: Your Urchin/Google Analytics account ID.
      def fb_google_analytics(uacct, options={})
        options = options.dup
        tag "fb:google-analytics", stringify_vals(options.merge(:uacct => uacct))
      end
      
      # Render if-is-app-user tag
      # This tag renders the enclosing content only if the user specified has accepted the terms of service for the application. 
      # Use fb_if_user_has_added_app to determine wether the user has added the app.
      # Example: 
      # <% fb_if_is_app_user(@facebook_user) do %>
      # 			  Thanks for accepting our terms of service!
      # 			<% fb_else do %>
      # 			  Hey you haven't agreed to our terms.  <%= link_to("Please accept our terms of service.", :action => "terms_of_service") %>
      # 			<% end %>
      #<% end %>       
      def fb_if_is_app_user(user=nil,options={},&proc)
        content = capture(&proc) 
        options = options.dup
        options.merge!(:uid=>cast_to_facebook_id(user)) if user
        concat(content_tag("fb:if-is-app-user",content,stringify_vals(options)),proc.binding)
      end

      # Render if-user-has-added-app tag
      # This tag renders the enclosing content only if the user specified has installed the application 
      #
      # Example: 
      # <% fb_if_user_has_added_app(@facebook_user) do %>
      # 			  Hey you are an app user!
      # 			<% fb_else do %>
      # 			  Hey you aren't an app user.  <%= link_to("Add App and see the other side.", :action => "added_app") %>
      # 			<% end %>
      #<% end %>       
      def fb_if_user_has_added_app(user,options={},&proc)
        content = capture(&proc) 
        options = options.dup
        concat(content_tag("fb:if-user-has-added-app",content,stringify_vals(options.merge(:uid=>cast_to_facebook_id(user)))),proc.binding)
      end
      
      # Render fb:if-is-user tag
      # This tag only renders enclosing content if the user is one of those specified
      # user can be a single user or an Array of users
      # Example:
      # <% fb_if_is_user(@check_user) do %>
      # 			     <%= fb_name(@facebook_user) %> are one of the users. <%= link_to("Check the other side", :action => "friend") %>
      # 			<% fb_else do %>
      # 			  <%= fb_name(@facebook_user) %>  are not one of the users  <%= fb_name(@check_user) %>
      # 			    <%= link_to("Check the other side", :action => "you") %>
      # 			<% end %>
      # <% end %>             
      def fb_if_is_user(user,&proc)
        content = capture(&proc) 
        user = [user] unless user.is_a? Array
        user_list=user.map{|u| cast_to_facebook_id(u)}.join(",")
        concat(content_tag("fb:if-is-user",content,{:uid=>user_list}),proc.binding)
      end
      
      # Render fb:else tag
      # Must be used within if block such as fb_if_is_user or fb_if_is_app_user . See example in fb_if_is_app_user
      def fb_else(&proc)
        content = capture(&proc) 
        concat(content_tag("fb:else",content),proc.binding)
      end
      
      #
      # Return the URL for the about page of the application
      def fb_about_url
        "http://#{Facebooker.www_server_base_url}/apps/application.php?api_key=#{Facebooker.api_key}"
      end
      
      #
      # Embed a discussion board named xid on the current page
      # 
      def fb_board(xid,options={})
        options = options.dup
        tag("fb:board",stringify_vals(options.merge(:xid=>xid)))
      end
      
      def fb_add_profile_section
        tag "fb:add-section-button",:section=>"profile"
      end
      
      def fb_add_info_section
        tag "fb:add-section-button",:section=>"info"
      end
      
      def fb_prompt_permission(permission,message,callback=nil)
        raise(ArgumentError, "Unknown value for permission: #{permission}") unless VALID_PERMISSIONS.include?(permission.to_sym)
        args={:perms=>permission}
        args[:next_fbjs]=callback unless callback.nil?
        content_tag("fb:prompt-permission",message,args)
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
      def stringify_vals(hash)
        result={}
        hash.each do |key,value|
          result[key]=value.to_s
        end
        result
      end
      
      def fb_status_msg(type, message, text)
        if text.blank?
          tag("fb:#{type}", :message => message)
        else
          content_tag("fb:#{type}", content_tag("fb:message", message) + text)
        end
      end

      def token_tag
        unless protect_against_forgery?
          ''
        else
          tag(:input, :type => "hidden", :name => request_forgery_protection_token.to_s, :value => form_authenticity_token)
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

  # We can allow css attributes.
  FB_ALWAYS_VALID_OPTION_KEYS = [:class, :style]
  def assert_valid_keys(*valid_keys)
    unknown_keys = keys - [valid_keys + FB_ALWAYS_VALID_OPTION_KEYS].flatten
    raise(ArgumentError, "Unknown key(s): #{unknown_keys.join(", ")}") unless unknown_keys.empty?
  end    
end
