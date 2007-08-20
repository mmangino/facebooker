require 'facebooker/model'
module Facebooker
  class Group
    class Membership
      include Model
      attr_accessor :position, :gid, :uid
    end
    include Model
    attr_accessor :pic, :pic_small, :pic_big, :name, :creator, :recent_news, :gid, :update_time, :group_subtype, :group_type, :website, :office, :description, :venue, :nid
    
    def members
      @members ||= memberships.map do |membership|
        User.new(membership.uid, session)
      end
    end
    def memberships
      @memberships ||= session.post('facebook.groups.getMembers', :gid => gid).map do |hash|
        Membership.from_hash(hash) do |membership|
          membership.gid = gid
        end
      end
    end
  end
end