require 'rexml/document'
require 'facebooker/session'
module Facebooker
  class Parser
    
    def self.parse(method, data)
      Errors.process(data)
      parser = Parser::PARSERS[method]
      parser.process(
        data
      )
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
        element.children.first.to_s.strip
      else
        hashinate(element)
      end
    end
    
    def self.hashinate(response_element)
      response_element.children.reject{|c| c.kind_of? REXML::Text}.inject({}) do |hash, child|
        hash[child.name] = if child.children.size == 1 && child.children.first.kind_of?(REXML::Text)
          child.children.first.to_s.strip
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
      element('auth_createToken_response', data).children.first.to_s.strip
    end
  end

  class GetSession < Parser#:nodoc:
    def self.process(data)      
      response_element = element('auth_getSession_response', data)
      hashinate(response_element)
    end
  end
  
  class GetFriends < Parser#:nodoc:
    def self.process(data)
      response_element = element('friends_get_response', data)
      friend_uids = []
      response_element.elements.each('uid') do |element|
        friend_uids << element.children.first.to_s.strip
      end
      friend_uids
    end
  end
 
  class UserInfo < Parser#:nodoc:
    def self.process(data)
      response_element = element('users_getInfo_response', data)
      users = []
      response_element.elements.each('user') do |element|
        users << hashinate(element)
      end
      users
    end
  end
  
  class PublishStoryToUser < Parser#:nodoc:
    def self.process(data)
      response_element = element('feed_publishStoryToUser_response', data)
      response_element.children.first.to_s.strip
    end
  end
  
  class PublishActionOfUser < Parser#:nodoc:
    def self.process(data)
      response_element = element('feed_publishActionOfUser_response', data)
      response_element.children.first.to_s.strip
    end
  end  
  
  class GetAppUsers < Parser#:nodoc:
    def self.process(data)
      response_element = element('friends_getAppUsers_response', data)
      users = []
      response_element.elements.each('uid') do |element|
        users << element.children.first.to_s.strip
      end
      users
    end
  end
  
  class NotificationsGet < Parser#:nodoc:
    def self.process(data)
      response_element = element('notifications_get_response', data)
      hashinate(response_element)
    end
  end
  
  class NotificationsSend < Parser#:nodoc:
    def self.process(data)
      response_element = element('notifications_send_response', data)
      hashinate(response_element)
    end
  end
  
  class GetAlbums < Parser#nodoc:
    def self.process(data)
      response_element = element('photos_getAlbums_response', data)
      albums = []
      response_element.elements.each('album') do |element|
        album = hashinate(element)
        albums << album
      end
      albums
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
      'facebook.friends.getAppUsers' => GetAppUsers,
      'facebook.photos.getAlbums' => GetAlbums,
      'facebook.notifications.send' => NotificationsSend
    }
  end
end
