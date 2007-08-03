require 'facebooker/model'
require 'facebooker/affiliation'
require 'facebooker/work_info'

module Facebooker
  # 
  # Holds attributes and behavior for a Facebook User
  class User
    include Model
    class Status
      include Model
      attr_accessor :message, :time
    end
    FIELDS = [:status, :political, :pic_small, :name, :quotes, :is_app_user, :tv, :profile_update_time, :meeting_sex, :hs_info, :timezone, :relationship_status, :hometown_location, :about_me, :wall_count, :significant_other_id, :pic_big, :music, :uid, :work_history, :sex, :religion, :notes_count, :activities, :pic_square, :movies, :has_added_app, :education_history, :birthday, :first_name, :meeting_for, :last_name, :interests, :current_location, :pic, :books, :affiliations]
    attr_accessor :id
    attr_accessor *FIELDS
    attr_reader :affiliations
    hash_settable_accessor :current_location, Location
    hash_settable_accessor :hometown_location, Location
    hash_settable_accessor :hs_info, EducationInfo::HighschoolInfo
    hash_settable_accessor :status, Status
    hash_settable_list_accessor :affiliations, Affiliation
    hash_settable_list_accessor :education_history, EducationInfo
    hash_settable_list_accessor :work_history, WorkInfo

    def initialize(id, session, attributes = {})
      @id = id
      @session = session
      populate_from_hash!(attributes)
    end
    
    ##
    # Retrieve friends
    def friends
      @friends ||= @session.post('facebook.friends.get').map do |uid|
        User.new(uid, @session)
      end
    end
    
    ###
    # Retrieve friends with user info populated
    # Subsequent calls will be retrieved from memory.
    # TODO: allow optional forced refresh
    def friends!
      @friends ||= @session.post('facebook.users.getInfo', :fields => FIELDS.join(','), :uids => friends.map{|f| f.id}.join(',')).map do |hash|
        User.new(hash['uid'], @session, hash)
      end
    end
    
    def notifications
      @notifications ||= Notifications.from_hash(@session.post('facebook.notifications.get'))
    end
    
    
    def publish_story(story)
      publish(story)
    end
    
    def publish_action(action)
      publish(action)
    end
    
    private
    def publish(feed_story_or_action)
      @session.post(Facebooker::Feed::METHODS[feed_story_or_action.class.name.split(/::/).last], feed_story_or_action.to_params) == "1" ? true : false
    end
    
  end  
end