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
  
      cattr_accessor :ignore_errors
      attr_accessor :_body
  
      include ActionView::Helpers::UrlHelper
      include ActionController::UrlWriter  # This must come after the include for 
                                           # ActionView::Helpers::UrlHelper or 
                                           # else url_for gets overridden
      include ActionView::Helpers::TextHelper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::AssetTagHelper
      include Facebooker::Rails::Helpers

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
        recipients = recipients.map {|r| Facebooker::User.cast_to_facebook_id(r)} unless recipients.blank?
        case _body
        when Facebooker::Feed::TemplatizedAction,Facebooker::Feed::Action
          from.publish_action(_body)
        when Facebooker::Feed::Story
          @recipients.each {|r| r.publish_story(_body)}
        when Notification
          from.session.send_notification(recipients,_body.fbml)
        when Email
          from.session.send_email(recipients, 
                                             _body.title, 
                                             _body.text, 
                                             _body.fbml)
        else
          raise UnspecifiedBodyType.new("You must specify a valid send_as")
        end
      end
  
  
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
    
    
      end
    end
  end
end