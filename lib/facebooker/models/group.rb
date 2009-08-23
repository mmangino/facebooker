require 'facebooker/model'
module Facebooker
  class Group
    ##
    # The model of a user's relationship to a group.  Users can occupy different positions within a group (e.g. 'owner')
    class Membership
      include Model
      attr_accessor :position, :gid, :uid
    end
    include Model
    attr_accessor :pic, :pic_small, :pic_big, :name, :creator, :recent_news, :update_time, :group_subtype, :group_type, :website, :office, :description, :venue, :nid, :privacy

    id_is :gid

    ##
    # Get the full list of members as populated User objects.  First time fetches group members via Facebook API call.  
    # Subsequent calls return cached values.
    # This is a convenience method for getting all of the Membership instances and instantiating User instances for each Membership.
    def members
      @members ||= memberships.map do |membership|
        User.new(membership.uid, session)
      end
    end
    
    ##
    # Get a list of Membership instances associated with this Group.  First call retrieves the Membership instances via a Facebook
    # API call.  Subsequent calls are retrieved from in-memory cache.
    def memberships
      @memberships ||= session.post('facebook.groups.getMembers', :gid => gid).map do |hash|
        Membership.from_hash(hash) do |membership|
          membership.gid = gid
        end
      end
    end
  end
end
