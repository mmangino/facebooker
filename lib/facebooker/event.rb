require 'facebooker/model'
module Facebooker
  class Event
    class Attendance
      include Model
      attr_accessor :eid, :uid, :rsvp_status
      def event
        @event ||= session.post('facebook.events.get', :eids => [eid])
      end
    end
    include Model
    attr_accessor :eid, :pic, :pic_small, :pic_big, :name, :creator, :update_time, :description, :tagline, :venue, :host, :event_type, :nid, :location, :end_time, :start_time, :event_subtype
  end
end