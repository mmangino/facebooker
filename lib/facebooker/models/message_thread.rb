require 'facebooker/model'
module Facebooker
  class MessageThread
    include Model
    
    id_is :thread_id
    attr_accessor :subject, :updated_time, :recipients
    attr_accessor :parent_message_id, :parent_thread_id, :message_count
    attr_accessor :snippet, :snippet_author, :object_id, :unread
    
    class Message
      include Model
      
      attr_accessor :message_id, :author_id, :body, :created_time, :attachment, :thread_id
      
      # An attachment can be a photo, a video, or a link
      class Attachment
        include Model
        
        attr_accessor :name, :href, :icon, :caption, :description
        
        # The Facebook messages API is in beta, this helper method is supposed to fail anytime soon
        def video?
          self.href =~ /\Ahttp:\/\/www\.facebook\.com\/video\/video\.php.*/
        end
        
        # The Facebook messages API is in beta, this helper method is supposed to fail anytime soon
        def photo?
          self.href =~ /\Ahttp:\/\/www\.facebook\.com\/photo\.php.*/
        end
        
        # The Facebook messages API is in beta, this helper method is supposed to fail anytime soon
        def link?
          !video? && !photo?
        end
      end
      hash_settable_accessor :attachment, Facebooker::MessageThread::Message::Attachment
    end
    hash_settable_list_accessor :messages, Facebooker::MessageThread::Message
    
  end
end

# Example of attachments

# -- Photo --

# <attachment>
#   <media list="true"/>
#   <href>http://www.facebook.com/photo.php?pid=12345&amp;id=54321</href>
#   <properties list="true"/>
#   <icon>http://b.static.ak.fbcdn.net/rsrc.php/zB010/hash/9yvl71tw.gif</icon>
#   <fb_object_type/>
#   <fb_object_id/>
#   <tagged_ids list="true"/>
# </attachment>

# -- Webcam video --

# <attachment>
#   <media list="true"/>
#   <name>Feb 10, 2010 1:26pm</name>
#   <href>http://www.facebook.com/video/video.php?v=12345</href>
#   <properties list="true"/>
#   <icon>http://static.ak.fbcdn.net/rsrc.php/zB010/hash/9yvl71tw.gif</icon>
#   <fb_object_type/>
#   <fb_object_id/>
#   <tagged_ids list="true"/>
# </attachment>

# -- Link --

# <attachment>
#   <media list="true">
#     <stream_media>
#       <href>http://www.facebook.com/l.php?u=http%253A%252F%252Fwww.google.fr%252F&amp;h=e46dd63cdbfadb74958fbe44e98f339c</href>
#       <type>link</type>
#       <src>http://external.ak.fbcdn.net/safe_image.php?d=dd54bba6b6e6479a89bb8084573c02c8&amp;w=90&amp;h=90&amp;url=http%3A%2F%2Fwww.google.fr%2Fintl%2Ffr_fr%2Fimages%2Flogo.gif</src>
#     </stream_media>
#   </media>
#   <name>Google</name>
#   <href>http://www.facebook.com/l.php?u=http%253A%252F%252Fwww.google.fr%252F&amp;h=e46dd63cdbfadb74958fbe44e98f339c</href>
#   <caption>www.google.fr</caption>
#   <properties list="true"/>
#   <icon>http://b.static.ak.fbcdn.net/rsrc.php/zB010/hash/9yvl71tw.gif</icon>
#   <fb_object_type/>
#   <fb_object_id/>
#   <tagged_ids list="true"/>
# </attachment>
