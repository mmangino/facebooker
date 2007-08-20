require 'facebooker/model'
module Facebooker
  class Group
    include Model
    attr_accessor :pic, :pic_small, :pic_big, :name, :creator, :recent_news, :gid, :update_time, :group_subtype, :group_type, :website, :office, :description, :venue, :nid
  end
end