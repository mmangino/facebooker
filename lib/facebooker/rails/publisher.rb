module Facebooker
  module Rails
    # ActionMailer like module for publishing Facbook messages
    # 
    # To use, create a subclass and define methods
    # Each method should start by calling send_as to specify the type of message
    # Valid options are :action, :templatized_action, :story, :email and :notification
    # 
    #
    # Below is an example of each type
    #
    #   class TestPublisher < Facebooker::Rails::Publisher
    #     # Action is published using the session of the from user
    #     def action(f)
    #       send_as :action
    #       from f
    #       title "Action Title"
    #       body "Body FBML here #{fb_name(f)} #{link_to "text",new_invitation_url}"
    #     end
    #
    #     # The new message templates are supported as well
    #     # First, create a method that contains your templates:
    #     # You may include multiple one line story templates and short story templates
    #     # but only one full story template
    #     #  Your most specific template should be first
    #     #
    #     # Before using, you must register your template by calling register. For this example
    #     #  You would call TestPublisher.register_publish_action
    #     #  Registering the template will store the template id returned from Facebook in the 
    #     # facebook_templates table that is created when you create your first publisher
    #     def publish_action_template
    #       one_line_story_template "{*actor*} did stuff with {*friend*}"
    #       one_line_story_template "{*actor*} did stuff"
    #       short_story_template "{*actor*} has a title {*friend*}", render(:partial=>"short_body")
    #       short_story_template "{*actor*} has a title", render(:partial=>"short_body")
    #       full_story_template "{*actor*} has a title {*friend*}", render(:partial=>"full_body")    
    #     end
    #
    #     # To send a registered template, you need to create a method to set the data
    #     # The publisher will look up the template id from the facebook_templates table
    #     def publish_action(f)
    #       send_as :user_action
    #       from f
    #       data :friend=>"Mike"
    #     end
    #   
    #     # Templatized Action uses From
    #     def templatized_action(f)
    #       send_as :templatized_action
    #       from f
    #       title_template "Templatized Action Title {name}"
    #       title_data :name=>"Mike"
    #     end
    #     # story is published to the story of the to user
    #     def story(to)
    #       send_as :story
    #       recipients to
    #       title 'Story Title'
    #     end
    #  
    #     # Provide a from user to send a general notification
    #     # if from is nil, this will send an announcement
    #     def notification(to,f)
    #       send_as :notification
    #       recipients to
    #       from f
    #       fbml "Not"
    #     end
    #  
    #     def email(to,f)
    #       send_as :email
    #       recipients to
    #       from f
    #       title "Email"
    #       fbml 'text'
    #       text fbml
    #     end
    #     # This will render the profile in /users/profile.erb
    #     #   it will set @user to user_to_update in the template
    #     #  The mobile profile will be rendered from the app/views/test_publisher/_mobile.erb
    #     #   template
    #     def profile_update(user_to_update,user_with_session_to_use)
    #       send_as :profile
    #       from user_with_session_to_use
    #       to user_to_update
    #       profile render(:action=>"/users/profile",:assigns=>{:user=>user_to_update})
    #       profile_action "A string"
    #       mobile_profile render(:partial=>"mobile",:assigns=>{:user=>user_to_update})
    #   end
    #
    #     #  Update the given handle ref with the content from a
    #     #   template
    #     def ref_update(user)
    #       send_as :ref
    #       from user
    #       fbml render(:action=>"/users/profile",:assigns=>{:user=>user_to_update})
    #       handle "a_ref_handle"
    #   end
    #
    #
    # To send a message, use ActionMailer like semantics
    #    TestPublisher.deliver_action(@user)
    #
    # For testing, you may want to create an instance of the underlying message without sending it
    #  TestPublisher.create_action(@user)
    # will create and return an instance of Facebooker::Feeds::Action
    #
    # Publisher makes many helpers available, including the linking and asset helpers
    class Publisher
      
      class FacebookTemplate < ::ActiveRecord::Base
        def self.register(t_id,name)
          t=find_or_initialize_by_template_name(name)
          t.update_attribute(:bundle_id,t_id)
          t
        end

        def self.for(name)
          find_by_template_name(name).bundle_id rescue nil
        end
      end
      
      class_inheritable_accessor :master_helper_module
      attr_accessor :one_line_story_templates, :short_story_templates
      
      cattr_accessor :skip_registry
      self.skip_registry = false
      
      
      class InvalidSender < StandardError; end
      class UnknownBodyType < StandardError; end
      class UnspecifiedBodyType < StandardError; end
      class Email
        attr_accessor :title
        attr_accessor :text
        attr_accessor :fbml
      end
  
      class Notification
        attr_accessor :fbml
      end
  
      class Profile
        attr_accessor :profile
        attr_accessor :profile_action
        attr_accessor :mobile_profile
        attr_accessor :profile_main
      end
      class Ref
        attr_accessor :handle
        attr_accessor :fbml
      end
      class UserAction
        attr_accessor :data
        attr_accessor :target_ids
        attr_accessor :body_general
        attr_accessor :template_id
        attr_accessor :template_name
        
        def template_id
          @template_id || FacebookTemplate.for(template_name)
        end

        def target_ids=(val)
          @target_ids = val.is_a?(Array) ? val.join(",") : val
        end
        
      end
      
      cattr_accessor :ignore_errors
      attr_accessor :_body
    
  

      def recipients(*args)
        if args.size==0
          @recipients
        else
          @recipients=args.first
        end
      end
      
      def from(*args)
        if args.size==0
          @from
        else
          @from=args.first
        end        
      end


      def send_as(option)
        self._body=case option
        when :action
          Facebooker::Feed::Action.new
        when :story
          Facebooker::Feed::Story.new
        when :templatized_action
          Facebooker::Feed::TemplatizedAction.new
        when :notification
          Notification.new
        when :email
          Email.new
        when :profile
          Profile.new
        when :ref
          Ref.new
        when :user_action
          UserAction.new
        else
          raise UnknownBodyType.new("Unknown type to publish")
        end
      end
      
      def full_story_template(title=nil,body=nil,params={})
        if title.nil?
          @full_story_template
        else
          @full_story_template=params.merge(:template_title=>title, :template_body=>body)
        end
      end
      
      def one_line_story_template(str)
        @one_line_story_templates ||= []
        @one_line_story_templates << str
      end
      
      def short_story_template(title,body,params={})
        @short_story_templates ||= []
        @short_story_templates << params.merge(:template_title=>title, :template_body=>body)
      end
      
      def method_missing(name,*args)
        if args.size==1 and self._body.respond_to?("#{name}=")
          self._body.send("#{name}=",*args)
        elsif self._body.respond_to?(name)
          self._body.send(name,*args)
        else
          super
        end
      end
      
      def image(src,target)
        {:src=>image_path(src),:href=> target.respond_to?(:to_str) ? target : url_for(target)}
      end
  
      def requires_from_user?(from,body)
        ! (announcement_notification?(from,body) or ref_update?(body) or profile_update?(body))
      end
      
      def profile_update?(body)
        body.is_a?(Profile)
      end
      
      def ref_update?(body)
        body.is_a?(Ref)
      end
  
      def announcement_notification?(from,body)
        from.nil? and body.is_a?(Notification)
      end
      
      def send_message(method)
        @recipients = @recipients.is_a?(Array) ? @recipients : [@recipients]
        if from.nil? and @recipients.size==1 and requires_from_user?(from,_body)
          @from = @recipients.first
        end
        # notifications can 
        # omit the from address
        raise InvalidSender.new("Sender must be a Facebooker::User") unless from.is_a?(Facebooker::User) || !requires_from_user?(from,_body)
        case _body
        when Facebooker::Feed::TemplatizedAction,Facebooker::Feed::Action
          from.publish_action(_body)
        when Facebooker::Feed::Story
          @recipients.each {|r| r.publish_story(_body)}
        when Notification
          (from.nil? ? Facebooker::Session.create : from.session).send_notification(@recipients,_body.fbml)
        when Email
          from.session.send_email(@recipients, 
                                             _body.title, 
                                             _body.text, 
                                             _body.fbml)
        when Profile
         # If recipient and from aren't the same person, create a new user object using the
         # userid from recipient and the session from from
         @from = Facebooker::User.new(Facebooker::User.cast_to_facebook_id(@recipients.first),Facebooker::Session.create) 
         @from.set_profile_fbml(_body.profile, _body.mobile_profile, _body.profile_action, _body.profile_main)
        when Ref
          Facebooker::Session.create.server_cache.set_ref_handle(_body.handle,_body.fbml)
        when UserAction
          @from.session.publish_user_action(_body.template_id || FacebookTemplate.for(method) ,_body.data||{},_body.target_ids,_body.body_general)
        else
          raise UnspecifiedBodyType.new("You must specify a valid send_as")
        end
      end

      # nodoc
      # needed for actionview
      def logger
        RAILS_DEFAULT_LOGGER
      end

      # nodoc
      # delegate to action view. Set up assigns and render
      def render(opts)
        opts = opts.dup
        body = opts.delete(:assigns) || {}
        initialize_template_class(body.dup.merge(:controller=>self)).render(opts)
      end


      def initialize_template_class(assigns)
        template_root = "#{RAILS_ROOT}/app/views"
	      controller_root = File.join(template_root,self.class.controller_path)
        #only do this on Rails 2.1
	      if ActionController::Base.respond_to?(:append_view_path)
  	      # only add the view path once
	        ActionController::Base.append_view_path(controller_root) unless ActionController::Base.view_paths.include?(controller_root)
	      end
        returning ActionView::Base.new([template_root,controller_root], assigns, self) do |template|
          template.controller=self
          template.extend(self.class.master_helper_module)
        end
      end
  
      
      self.master_helper_module = Module.new
      self.master_helper_module.module_eval do
        # url_helper delegates to @controller, 
        # so we need to define that in the template
        # we make it point to the publisher
        include ActionView::Helpers::UrlHelper
        include ActionView::Helpers::TextHelper
        include ActionView::Helpers::TagHelper
        include ActionView::Helpers::FormHelper
        include ActionView::Helpers::FormTagHelper
        include ActionView::Helpers::AssetTagHelper
        include Facebooker::Rails::Helpers
        
        #define this for the publisher views
        def protect_against_forgery?
          @paf ||= ActionController::Base.new.send(:protect_against_forgery?)
        end
      end
      ActionController::Routing::Routes.named_routes.install(self.master_helper_module)
      include self.master_helper_module
      # Publisher is the controller, it should do the rewriting
      include ActionController::UrlWriter
      class <<self
        
        def register_all_templates
          all_templates = instance_methods.grep(/_template$/) - %w(short_story_template full_story_template one_line_story_template) 
          all_templates.each do |template|
            template_name=template.sub(/_template$/,"")
            puts "Registering #{template_name}"
            send("register_"+template_name)
          end
        end
        
        def method_missing(name,*args)
          should_send=false
          method=""
          if md=/^create_(.*)$/.match(name.to_s)
            method=md[1]
          elsif md=/^deliver_(.*)$/.match(name.to_s)
            method=md[1]
            should_send=true
          elsif md=/^register_(.*)$/.match(name.to_s)
            (publisher=new).send(md[1]+"_template")
            template_id = Facebooker::Session.create.register_template_bundle(publisher.one_line_story_templates,publisher.short_story_templates,publisher.full_story_template)
            FacebookTemplate.register(template_id,md[1]) unless skip_registry
            return template_id
          else
            super
          end
      
          #now create the item
          (publisher=new).send(method,*args)
          case publisher._body
          when UserAction
            publisher._body.template_name=method
          end
          
          should_send ? publisher.send_message(method) : publisher._body
        end
    
        def default_url_options
          {:host => Facebooker.canvas_server_base + Facebooker.facebook_path_prefix}
        end
    
        def controller_path
          self.to_s.underscore
        end
        
        def helper(*args)
          args.each do |arg|
            case arg
            when Symbol,String
              add_template_helper("#{arg.to_s.classify}Helper".constantize)              
            when Module
              add_template_helper(arg)
            end
          end
        end
        
        def add_template_helper(helper_module) #:nodoc:
          master_helper_module.send :include,helper_module
          include master_helper_module
        end

    
        def inherited(child)
          super          
          child.master_helper_module=Module.new
          child.master_helper_module.__send__(:include,self.master_helper_module)
          child.send(:include, child.master_helper_module)      
        end
    
      end
    end
  end
end
