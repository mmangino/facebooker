require 'facebooker/model'
require 'facebooker/models/affiliation'
require 'facebooker/models/work_info'
require 'facebooker/models/family_relative_info'
module Facebooker
  # 
  # Holds attributes and behavior for a Facebook User
  class User
    include Model
    class Status
      include Model
      attr_accessor :message, :time, :status_id
    end
    FIELDS = [:status, :political, :pic_small, :name, :quotes, :is_app_user, :tv, :profile_update_time, :meeting_sex, :hs_info, :timezone, :relationship_status, :hometown_location, :about_me, :wall_count, :significant_other_id, :pic_big, :music, :work_history, :sex, :religion, :notes_count, :activities, :pic_square, :movies, :has_added_app, :education_history, :birthday, :birthday_date, :first_name, :meeting_for, :last_name, :interests, :current_location, :pic, :books, :affiliations, :locale, :profile_url, :proxied_email, :email_hashes, :allowed_restrictions, :pic_with_logo, :pic_big_with_logo, :pic_small_with_logo, :pic_square_with_logo, :online_presence, :verified, :profile_blurb, :username, :website, :is_blocked, :family]
    STANDARD_FIELDS = [:uid, :first_name, :last_name, :name, :timezone, :birthday, :sex, :affiliations, :locale, :profile_url, :proxied_email]
    populating_attr_accessor(*FIELDS)
    attr_reader :affiliations
    populating_hash_settable_accessor :current_location, Location
    populating_hash_settable_accessor :hometown_location, Location
    populating_hash_settable_accessor :hs_info, EducationInfo::HighschoolInfo
    populating_hash_settable_list_accessor :affiliations, Affiliation
    populating_hash_settable_list_accessor :education_history, EducationInfo
    populating_hash_settable_list_accessor :work_history, WorkInfo
    populating_hash_settable_list_accessor :family, FamilyRelativeInfo

    populating_attr_reader :status

    # Can pass in these two forms:
    # id, session, (optional) attribute_hash
    # attribute_hash
    def initialize(*args)
      @friends            = nil
      @current_location   = nil
      @pic                = nil
      @hometown_location  = nil
      @populated          = false
      @session            = nil
      @id                 = nil
      if (args.first.kind_of?(String) || args.first.kind_of?(Integer)) && args.size==1
        self.uid = args.shift
        @session = Session.current
      elsif (args.first.kind_of?(String) || args.first.kind_of?(Integer)) && args[1].kind_of?(Session)
        self.uid = args.shift
        @session = args.shift
      end
      if args.last.kind_of?(Hash)
        populate_from_hash!(args.pop)
      end
    end

    id_is :uid
    alias :facebook_id :id

    # Returns a user's events, params correspond to API call parameters (except UID):
    # http://wiki.developers.facebook.com/index.php/Events.get
    # E.g:
    #  @user.events(:start_time => Time.now, :end_time => 1.month.from_now)
    #  # => Returns events betwen now and a month from now
    def events(params={})
      @events ||= {}
      [:start_time,:end_time].compact.each do |key|
        params[key] = params[key].to_i
      end
#      puts @events[params.to_s].nil?
      @events[params.to_s] ||= @session.post('facebook.events.get', {:uid => self.id}.merge(params)).map do |event|
        Event.from_hash(event)
      end
    end

    # Rsvp to an event with the eid and rsvp_status which can be 'attending', 'unsure', or 'declined'.
    # http://wiki.developers.facebook.com/index.php/Events.rsvp
    # E.g:
    #  @user.rsvp_event('100321123', 'attending')
    #  # => Returns true if all went well
    def rsvp_event(eid, rsvp_status, options = {})
      result = @session.post('facebook.events.rsvp', options.merge(:eid => eid, :rsvp_status => rsvp_status))
      result == '1' ? true : false
    end
    
    # 
    # Set the list of friends, given an array of User objects.  If the list has been retrieved previously, will not set
    def friends=(list_of_friends,flid=nil)
      @friends_hash ||= {}
       flid=cast_to_friend_list_id(flid)
       #use __blank instead of nil so that this is cached
       cache_key = flid||"__blank"

      @friends_hash[cache_key] ||= list_of_friends
    end
    
    def cast_to_friend_list_id(flid)
      case flid
       when String
         list=friend_lists.detect {|f| f.name==flid}
         raise Facebooker::Session::InvalidFriendList unless list
         list.flid
       when FriendList
         flid.flid
       else
         flid
       end
     end
    ##
    # Retrieve friends
    def friends(flid = nil)
       @friends_hash ||= {}
       flid=cast_to_friend_list_id(flid)

       #use __blank instead of nil so that this is cached
       cache_key = flid||"__blank"
       options = {:uid=>self.id}
       options[:flid] = flid unless flid.nil?
       @friends_hash[cache_key] ||= @session.post('facebook.friends.get', options,false).map do |uid|
          User.new(uid, @session)
      end
      @friends_hash[cache_key]
    end

    def friend_ids
      options = {:uid => self.id}
      @session.post('facebook.friends.get', options, false)
    end

    ###
    # Publish a post into the stream on the user's Wall and News Feed.  This
    # post also appears in the user's friend's streams.  The +publish_stream+
    # extended permission must be granted in order to use this method.
    #
    # See: http://wiki.developers.facebook.com/index.php/Stream.publish
    #
    # +target+ can be the current user or some other user.
    #
    # Example:
    #   # Publish a message to my own wall:
    #   me.publish_to(me, :message => 'hello world')
    #
    #   # Publish to a friend's wall with an action link:
    #   me.publish_to(my_friend,  :message => 'how are you?', :action_links => [
    #     :text => 'my website',
    #     :href => 'http://tenderlovemaking.com/'
    #   ])
    def publish_to(target, options = {})
      @session.post('facebook.stream.publish', prepare_publish_to_options(target, options), false)
    end
   
    # Prepares options for the stream.publish
    def prepare_publish_to_options(target, options)
      opts = {:uid          => self.id,
              :target_id    => target.id,
              :message      => options[:message]} 

      if(attachment = options[:attachment] && Facebooker.json_encode(options[:attachment]))
        opts[:attachment] = attachment
      end
      if (links = options[:action_links] && Facebooker.json_encode(options[:action_links]))
        opts[:action_links] = links
      end
      opts
    end
    
    ###
    # Publish a comment on a post
    #
    # See: http://wiki.developers.facebook.com/index.php/Stream.addComment
    #
    # +post_id+ the post_id for the post that is being commented on
    # +comment+ the text of the comment
    def comment_on(post_id, comment)
      @session.post('facebook.stream.addComment', {:post_id=>post_id, :comment=>comment})
    end
    

     def friend_lists
       @friend_lists ||= @session.post('facebook.friends.getLists').map do |hash|
         friend_list = FriendList.from_hash(hash)
         friend_list.session = session
         friend_list
       end
     end
    ###
    # Retrieve friends with user info populated
    # Subsequent calls will be retrieved from memory.
    # Optional: list of fields to retrieve as symbols
    def friends!(*fields)
      @friends ||= session.post('facebook.users.getInfo', :fields => collect(fields), :uids => friends.map{|f| f.id}.join(',')).map do |hash|  
        User.new(hash['uid'], session, hash)
      end
    end
    
    ###
    # Retrieve profile data for logged in user
    # Optional: list of fields to retrieve as symbols
    def populate(*fields)
      session.post('facebook.users.getInfo', :fields => collect(fields), :uids => id) do |response|
        populate_from_hash!(response.first)
      end
    end
        
    def friends_with?(user_or_id)
      friends.map{|f| f.to_i}.include?(user_or_id.to_i)  
    end
    
    def friends_with_this_app
      @friends_with_this_app ||= friend_ids_with_this_app.map do |uid|
        User.new(uid, session)
      end
    end

    def friend_ids_with_this_app
      @friend_ids_with_this_app ||= session.post('facebook.friends.getAppUsers')
    end
    
    def groups(gids = [])
      args = gids.empty? ? {} : {:gids => gids}
      @groups ||= session.post('facebook.groups.get', args).map do |hash|
        group = Group.from_hash(hash)
        group.session = session
        group
      end
    end
    
    def notifications
      @notifications ||= Notifications.from_hash(session.post('facebook.notifications.get'))
    end
    
    def publish_story(story)
      publish(story)
    end
    
    def publish_action(action)
      publish(action)
    end
    
    def publish_templatized_action(action)
      publish(action)
    end
    
    def albums
      @albums ||= session.post('facebook.photos.getAlbums', :uid => self.id) do |response|
        response.map do |hash|
          Album.from_hash(hash)
        end
      end
    end
    
    def create_album(params)
      @album = session.post('facebook.photos.createAlbum', params) {|response| Album.from_hash(response)}
    end
    
    def profile_photos
      session.get_photos(nil, nil, profile_pic_album_id)
    end
    
    # Upload a photo to the user's profile.
    #
    # In your view, create a multipart form that posts directly to your application (not through canvas):
    #
    #   <% form_tag photos_url(:canvas => false), :html => {:multipart => true, :promptpermission => 'photo_upload'} do %>
    #     Photo: <%= file_field_tag 'photo' %>
    #     Caption: <%= text_area_tag 'caption' %>
    #     <%= submit_tag 'Upload Photo', :class => 'inputsubmit' %>
    #   <% end %>
    # 
    # And in your controller: 
    #
    #   class PhotosController < ApplicationController
    #     def create
    #       file = Net::HTTP::MultipartPostFile.new(
    #         params[:photo].original_filename,
    #         params[:photo].content_type,
    #         params[:photo].read
    #       )
    #     
    #       @photo = facebook_session.user.upload_photo(file, :caption => params[:caption])
    #       redirect_to photos_url(:canvas => true)
    #     end
    #   end
    #
    # Options correspond to http://wiki.developers.facebook.com/index.php/Photos.upload
    def upload_photo(multipart_post_file, options = {})
      Photo.from_hash(session.post_file('facebook.photos.upload',
        options.merge(nil => multipart_post_file)))
    end
    
    # Upload a video to the user's profile.
    #
    # In your view, create a multipart form that posts directly to your application (not through canvas):
    #
    #   <% form_tag videos_url(:canvas => false), :html => {:multipart => true, :promptpermission => 'video_upload'} do %>
    #     Video: <%= file_field_tag 'video' %>
    #     Title: <%= text_area_tag 'title' %>
    #     Description: <%= text_area_tag 'description' %>
    #     <%= submit_tag 'Upload Video', :class => 'inputsubmit' %>
    #   <% end %>
    # 
    # And in your controller: 
    #
    #   class VideosController < ApplicationController
    #     def create
    #       file = Net::HTTP::MultipartPostFile.new(
    #         params[:photo].original_filename,
    #         params[:photo].content_type,
    #         params[:photo].read
    #       )
    #     
    #       @video = facebook_session.user.upload_video(file, :description => params[:description])
    #       redirect_to videos_url(:canvas => true)
    #     end
    #   end
    #
    # Options correspond to http://wiki.developers.facebook.com/index.php/Video.upload
    def upload_video(multipart_post_file, options = {})
      Video.from_hash(session.post_file('facebook.video.upload',
        options.merge(nil => multipart_post_file, :base => Facebooker.video_server_base)))
    end
    
    def profile_fbml
      session.post('facebook.profile.getFBML', :uid => id)  
    end    
    
    ##
    # Set the profile FBML for this user
    #
    # This does not set profile actions, that should be done with profile_action=
    def profile_fbml=(markup)
      set_profile_fbml(markup, nil, nil, nil)
    end
    
    ##
    # Set the mobile profile FBML
    def mobile_fbml=(markup)
      set_profile_fbml(nil, markup, nil,nil)
    end
    
    def profile_action=(markup)
      set_profile_fbml(nil, nil, markup,nil)
    end
    
    def profile_main=(markup)
     set_profile_fbml(nil,nil,nil,markup)
    end
    
    def set_profile_fbml(profile_fbml, mobile_fbml, profile_action_fbml, profile_main = nil)
      parameters = {:uid => id}
      parameters[:profile] = profile_fbml if profile_fbml
      parameters[:profile_action] = profile_action_fbml if profile_action_fbml
      parameters[:mobile_profile] = mobile_fbml if mobile_fbml
      parameters[:profile_main] = profile_main if profile_main
      session.post('facebook.profile.setFBML', parameters,false)
    end
    
    ## ** NEW PROFILE DESIGN ***
    # Set a info section for this user
    #
    # Note: using set_profile_info as I feel using user.set_info could be confused with the user.getInfo facebook method.
    #       Also, I feel it fits in line with user.set_profile_fbml.
    def set_profile_info(title, info_fields, format = :text)
      session.post('facebook.profile.setInfo', :title => title, :uid => id, 
        :type => format.to_s == "text" ? 1 : 5, :info_fields => info_fields.to_json)
    end
    
    def get_profile_info
      session.post('facebook.profile.getInfo', :uid => id)
    end
    
    ##
    # This DOES NOT set the status of a user on Facebook
    # Use the set_status method instead
    def status=(message)
      case message
      when String,Status
        @status = message
      when Hash
        @status = Status.from_hash(message)
      end
    end
   

    ## 
    # Return +limit+ statuses from the user
    def statuses( limit = 50 )
      session.post('facebook.status.get', {:uid => uid, :limit => limit}).collect { |ret| Status.from_hash(ret) }
    end

    ##
    # Set the status for a user
    # DOES NOT prepend "is" to the message
    #
    # requires extended permission. 
    def set_status(message)
      self.status=message
      session.post('facebook.users.setStatus',{:status=>message,:status_includes_verb=>1,:uid => uid}, false) do |ret|
        ret
      end
    end
    
    ##
    # Checks to see if the user has enabled the given extended permission
    def has_permission?(ext_perm) # ext_perm = email, offline_access, status_update, photo_upload, create_listing, create_event, rsvp_event, sms
      session.post('facebook.users.hasAppPermission', {:ext_perm=>ext_perm, :uid => uid}, false) == "1"
    end    
    
    ##
    # Convenience method to check multiple permissions at once
    def has_permissions?(ext_perms)
      ext_perms.all?{|p| has_permission?(p)}
    end            
    
    ##
    # Convenience method to send email to the current user
    def send_email(subject, text=nil, fbml=nil)
      session.send_email([id], subject, text, fbml)
    end
    
    ##
    # Convenience method to set cookie for the current user
    def set_cookie(name, value, expires=nil, path=nil)
      session.data.set_cookie(id, name, value, expires, path)
    end
    
    ##
    # Convenience method to get cookies for the current user
    def get_cookies(name=nil)
      session.data.get_cookies(id, name)
    end
    
    ##
    # Returns the user's id as an integer
    def to_i
      id
    end
    
    def to_s
      id.to_s
    end
    
    ##
    # Two Facebooker::User objects should be considered equal if their Facebook ids are equal
    def ==(other_user)
      other_user.is_a?(User) && id == other_user.id
    end
    
    
    # register a user with Facebook
    # users should be a hast with at least an :email field
    # you can optionally provide an :account_id field as well
        
    def self.register(users)
      user_map={}
      users=users.map do |h|
        returning h.dup do |d|
          if email=d.delete(:email)
            hash = hash_email(email)
            user_map[hash]=h
            d[:email_hash]=hash
          end
        end
      end
      Facebooker::Session.create.post("facebook.connect.registerUsers",:accounts=>users.to_json) do |ret|
        ret.each do |hash|
          user_map.delete(hash)
        end
        unless user_map.empty?
          e=Facebooker::Session::UserRegistrationFailed.new
          e.failed_users = user_map.values
          raise e
        end
        ret
      end
    end

    # Get a count of unconnected friends
    def getUnconnectedFriendsCount
      session.post("facebook.connect.getUnconnectedFriendsCount")
    end


    # Unregister an array of email hashes
    def self.unregister(email_hashes)
      Facebooker::Session.create.post("facebook.connect.unregisterUsers",:email_hashes=>email_hashes.to_json) do |ret|
        ret.each do |hash|
          email_hashes.delete(hash)
        end
        unless email_hashes.empty?
          e=Facebooker::Session::UserUnRegistrationFailed.new
          e.failed_users = email_hashes
          raise e
        end
        ret
      end      
    end
    
    # unregister an array of email addresses
    def self.unregister_emails(emails)
      emails_hash  = {}
      emails.each {|e| emails_hash[hash_email(e)] = e}
      begin 
        unregister(emails_hash.keys).collect {|r| emails_hash[r]}
      rescue
        # re-raise with emails instead of hashes.
        e = Facebooker::Session::UserUnRegistrationFailed.new
        e.failed_users = $!.failed_users.collect { |f| emails_hash[f] }
        raise e
      end
    end
    
    def self.hash_email(email)
      email = email.downcase.strip
      crc=Zlib.crc32(email)
      md5=Digest::MD5.hexdigest(email)
      "#{crc}_#{md5}"
    end
    
    def self.cast_to_facebook_id(object)
      if object.respond_to?(:facebook_id)
        object.facebook_id
      else
        object
      end
    end
    
    def self.user_fields(fields = [])
      valid_fields(fields)
    end
    
    def self.standard_fields(fields = [])
      valid_fields(fields,STANDARD_FIELDS)
    end
    
    private
    def publish(feed_story_or_action)
      session.post(Facebooker::Feed::METHODS[feed_story_or_action.class.name.split(/::/).last], feed_story_or_action.to_params) == "1" ? true : false
    end
    
    def self.valid_fields(fields, allowable=FIELDS)
      allowable.reject{|field_name| !fields.empty? && !fields.include?(field_name)}.join(',')
    end
    
    def collect(fields, allowable=FIELDS)
      allowable.reject{|field_name| !fields.empty? && !fields.include?(field_name)}.join(',')
    end
    
    def profile_pic_album_id
      merge_aid(-3, id)
    end
    
    def merge_aid(aid, uid)
      (uid << 32) + (aid & 0xFFFFFFFF)
    end
    
  end
end
