module Facebooker
  module Feed
    METHODS = {'Action' => 'facebook.feed.publishActionOfUser', 'Story' => 'facebook.feed.publishStoryToUser',
               'TemplatizedAction' => 'facebook.feed.publishTemplatizedAction' }

    class ActionBase
      1.upto(4) do |num|
        attr_accessor "image_#{num}"
        attr_accessor "image_#{num}_link"
      end
      
      def add_image(image,link=nil)
        1.upto(4) do |num|
          if send("image_#{num}").blank?
            send("image_#{num}=",image)
            send("image_#{num}_link=",link) unless link.nil?
            return num
          end
        end        
      end
      

      protected
      def image_params
        image_hash = {}
        1.upto(4) do |num|
          image_attribute = "image_#{num}"
          image_link_attribute = image_attribute + "_link"
          self.__send__(image_attribute) ? image_hash[image_attribute] = self.__send__(image_attribute) : nil
          self.__send__(image_link_attribute) ? image_hash[image_link_attribute] = self.__send__(image_link_attribute) : nil    
        end
        image_hash
      end
    end

    ##
    # Representation of a templatized action to be published into a user's news feed
    class TemplatizedAction < ActionBase
     attr_accessor :page_actor_id, :title_template, :title_data, :body_template, :body_data, :body_general, :target_ids

      def to_params
       raise "Must set title_template" if self.title_template.nil?
       { :page_actor_id => page_actor_id, 
         :title_template => title_template, 
         :title_data => convert_json(title_data),
         :body_template => body_template, 
         :body_data => convert_json(body_data), 
         :body_general => body_general,
         :target_ids => target_ids }.merge image_params
      end
      
      def convert_json(hash_or_string)    
        (hash_or_string.is_a?(Hash) and hash_or_string.respond_to?(:to_json)) ? hash_or_string.to_json : hash_or_string
      end
    end

    ##
    # Representation of a story to be published into a user's news feed.
    class Story < ActionBase
      attr_accessor :title, :body

      ##
      # Converts Story to a Hash of its attributes for use as parameters to Facebook REST API calls
      def to_params
        raise "Must set title before converting" if self.title.nil?
        { :title => title, :body => body }.merge image_params
      end

    end
    Action = Story.dup
    def Action.name
      "Action"
    end
    ##
    #  Representation of an action to be published into a user's news feed.  Alias for Story.
    class Action; end
  end
end