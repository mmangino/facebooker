require 'rexml/document'
require 'facebooker/session'
module Facebooker
  class Parser
    
    module REXMLElementExtensions
      def text_value
        self.children.first.to_s.strip
      end
    end
    
    ::REXML::Element.__send__(:include, REXMLElementExtensions)
    
    def self.parse(method, data)
      Errors.process(data)
      parser = Parser::PARSERS[method]
      parser.process(
        data
      )
    end
    
    def self.array_of(response_element, element_name)
      values_to_return = []
      response_element.elements.each(element_name) do |element|
        values_to_return << yield(element)
      end
      values_to_return
    end
    
    def self.array_of_text_values(response_element, element_name)
      array_of(response_element, element_name) do |element|
        element.text_value
      end
    end

    def self.array_of_hashes(response_element, element_name)
      array_of(response_element, element_name) do |element|
        hashinate(element)
      end
    end
    
    def self.element(name, data)
      data = data.body rescue data # either data or an HTTP response
      doc = REXML::Document.new(data)
      doc.elements.each(name) do |element|
        return element
      end
      raise "Element #{name} not found in #{data}"
    end
    
    def self.hash_or_value_for(element)
      if element.children.size == 1 && element.children.first.kind_of?(REXML::Text)
        element.text_value
      else
        hashinate(element)
      end
    end
    
    def self.hashinate(response_element)
      response_element.children.reject{|c| c.kind_of? REXML::Text}.inject({}) do |hash, child|
        hash[child.name] = if child.children.size == 1 && child.children.first.kind_of?(REXML::Text)
          child.text_value
        else
          if child.attributes['list'] == 'true'
            child.children.reject{|c| c.kind_of? REXML::Text}.map do |subchild| 
                hash_or_value_for(subchild)
            end            
          else
            child.children.reject{|c| c.kind_of? REXML::Text}.inject({}) do |subhash, subchild|
              subhash[subchild.name] = hash_or_value_for(subchild)
              subhash
            end
          end
        end
        hash
      end      
    end
    
  end  
  
  class CreateToken < Parser#:nodoc:
    def self.process(data)
      element('auth_createToken_response', data).text_value
    end
  end

  class GetSession < Parser#:nodoc:
    def self.process(data)      
      hashinate(element('auth_getSession_response', data))
    end
  end
  
  class GetFriends < Parser#:nodoc:
    def self.process(data)
      array_of_text_values(element('friends_get_response', data), 'uid')
    end
  end
 
  class UserInfo < Parser#:nodoc:
    def self.process(data)
      array_of_hashes(element('users_getInfo_response', data), 'user')
    end
  end
  
  class PublishStoryToUser < Parser#:nodoc:
    def self.process(data)
      element('feed_publishStoryToUser_response', data).text_value
    end
  end
  
  class PublishActionOfUser < Parser#:nodoc:
    def self.process(data)
      element('feed_publishActionOfUser_response', data).text_value
    end
  end  
  
  class GetAppUsers < Parser#:nodoc:
    def self.process(data)
      array_of_text_values(element('friends_getAppUsers_response', data), 'uid')
    end
  end
  
  class NotificationsGet < Parser#:nodoc:
    def self.process(data)
      hashinate(element('notifications_get_response', data))
    end
  end
  
  class NotificationsSend < Parser#:nodoc:
    def self.process(data)
      element('notifications_send_response', data).text_value
    end
  end
  
  class GetAlbums < Parser#nodoc:
    def self.process(data)
      array_of_hashes(element('photos_getAlbums_response', data), 'album')
    end
  end
  
  class CreateAlbum < Parser#:nodoc:
    def self.process(data)
      hashinate(element('photos_createAlbum_response', data))
    end
  end  
  
  class SendRequest < Parser#:nodoc:
    def self.process(data)
      element('notifications_sendRequest_response', data).text_value
    end
  end
  
  class ProfileFBML < Parser#:nodoc:
    def self.process(data)
      element('profile_getFBML_response', data).text_value
    end
  end
  
  class ProfileFBMLSet < Parser#:nodoc:
    def self.process(data)
      element('profile_setFBML_response', data).text_value
    end
  end
  
  class SetRefHandle < Parser#:nodoc:
    def self.process(data)
      element('fbml_setRefHandle_response', data).text_value
    end
  end
  
  class RefreshRefURL < Parser#:nodoc:
    def self.process(data)
      element('fbml_refreshRefUrl_response', data).text_value
    end
  end
  
  class AreFriends < Parser#:nodoc:
    def self.process(data)
      array_of_hashes(element('friends_areFriends_response', data), 'friend_info').inject({}) do |memo, hash|
        memo[[Integer(hash['uid1']), Integer(hash['uid2'])].sort] = are_friends?(hash['are_friends'])
        memo
      end
    end
    
    private
    def self.are_friends?(raw_value)
      if raw_value == '1'
        true
      elsif raw_value == '0'
        false
      else
        nil
      end
    end
  end
    
  class Errors < Parser#:nodoc:
    EXCEPTIONS = {
      1 	=> Facebooker::Session::UnknownError,
      2 	=> Facebooker::Session::ServiceUnavailable,
      4 	=> Facebooker::Session::MaxRequestsDepleted,
      5 	=> Facebooker::Session::HostNotAllowed,
      100 => Facebooker::Session::MissingOrInvalidParameter,
      101 => Facebooker::Session::InvalidAPIKey,
      102 => Facebooker::Session::SessionExpired,
      103 => Facebooker::Session::CallOutOfOrder,
      104 => Facebooker::Session::IncorrectSignature
    }
    def self.process(data)
      response_element = element('error_response', data) rescue nil
      if response_element
        hash = hashinate(response_element)
        raise EXCEPTIONS[Integer(hash['error_code'])].new(hash['error_msg'])
      end
    end
  end
  
  class Parser
    PARSERS = {
      'facebook.auth.createToken' => CreateToken,
      'facebook.auth.getSession' => GetSession,
      'facebook.friends.get' => GetFriends,
      'facebook.users.getInfo' => UserInfo,
      'facebook.feed.publishStoryToUser' => PublishStoryToUser,
      'facebook.feed.publishActionOfUser' => PublishActionOfUser,
      'facebook.notifications.get' => NotificationsGet,
      'facebook.notifications.send' => NotificationsSend,
      'facebook.friends.getAppUsers' => GetAppUsers,
      'facebook.photos.getAlbums' => GetAlbums,
      'facebook.photos.createAlbum' => CreateAlbum,
      'facebook.notifications.sendRequest' => SendRequest,
      'facebook.profile.getFBML' => ProfileFBML,
      'facebook.profile.setFBML' => ProfileFBMLSet,
      'facebook.friends.areFriends' => AreFriends,
      'facebook.fbml.setRefHandle' => SetRefHandle,
      'facebook.fbml.refreshRefUrl' => RefreshRefURL
    }
  end
end
