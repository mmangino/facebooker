require 'facebooker/model'
module Facebooker
  class Event
    include Model
    attr_accessor :eid, :pic, :pic_small, :pic_big, :name, :creator, :update_time, :description, :tagline, :venue, :host, :event_type, :nid, :location, :end_time, :start_time, :event_subtype
  end
end