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
    # To send a message, use ActionMailer like semantics
    #    TestPublisher.deliver_action(@user)
    #
    # For testing, you may want to create an instance of the underlying message without sending it
    #  TestPublisher.create_action(@user)
    # will create and return an instance of Facebooker::Feeds::Action
    #
    # Publisher makes many helpers available, including the linking and asset helpers
    class Publisher
      
      class_inheritable_accessor :master_helper_module
      
      
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
      end
      class Ref
        attr_accessor :handle
        attr_accessor :fbml
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
        else
          raise UnknownBodyType.new("Unknown type to publish")
        end
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
  
      def send_message
        @recipients = @recipients.is_a?(Array) ? @recipients : [@recipients]
        if from.nil? and @recipients.size==1
          @from = @recipients.first
        end
        raise InvalidSender.new("Sender must be a Facebooker::User") unless from.is_a?(Facebooker::User)
        case _body
        when Facebooker::Feed::TemplatizedAction,Facebooker::Feed::Action
          from.publish_action(_body)
        when Facebooker::Feed::Story
          @recipients.each {|r| r.publish_story(_body)}
        when Notification
          from.session.send_notification(@recipients,_body.fbml)
        when Email
          from.session.send_email(@recipients, 
                                             _body.title, 
                                             _body.text, 
                                             _body.fbml)
        when Profile
         # If recipient and from aren't the same person, create a new user object using the
         # userid from recipient and the session from from
         if @from != @recipients.first
           @from = Facebooker::User.new(Facebooker::User.cast_to_facebook_id(@recipients.first),from.session) 
         end
         from.set_profile_fbml(_body.profile, 
                                            _body.mobile_profile, 
                                            _body.profile_action)
        when Ref
          @from.session.server_cache.set_ref_handle(_body.handle,_body.fbml)
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
        template_root = "#{RAILS_ROOT}/app/views/"
        returning ActionView::Base.new([template_root,File.join(template_root,self.class.controller_path)], assigns, self) do |template|
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
      end
      ActionController::Routing::Routes.named_routes.install(self.master_helper_module)
      include self.master_helper_module
      # Publisher is the controller, it should do the rewriting
      include ActionController::UrlWriter
      class <<self
        
        
        
        def method_missing(name,*args)
          should_send=false
          method=""
          if md=/^create_(.*)$/.match(name.to_s)
            method=md[1]
          elsif md=/^deliver_(.*)$/.match(name.to_s)
            method=md[1]
            should_send=true
          else
            super
          end
      
          #now create the item
          (publisher=new).send(method,*args)
          should_send ? publisher.send_message : publisher._body
        end
    
        def default_url_options
          {:host => "apps.facebook.com" + Facebooker.facebook_path_prefix}
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
          child.master_helper_module.send!(:include,self.master_helper_module)
          child.send(:include, child.master_helper_module)      
        end
    
      end
    end
  end
end