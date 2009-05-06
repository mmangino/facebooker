require 'facebooker/model'
module Facebooker
  class Event
    
    ##
    # The relationship between a Facebook user and an Event to which he or she has been
    # invited and may or may not be attending (based on #rsvp_status)
    class Attendance
      include Model
      attr_accessor :eid, :uid, :rsvp_status
      
      ##
      # Get the full, populated Event object which this Attendance is associated with.
      # First access will query the Facebook API (facebook.events.get).  Subsequent
      # calls are retrieved from in-memory cache.
      def event
        @event ||= Event.from_hash(session.post('facebook.events.get', :eids => [eid]).first)
      end
      
      #TODO: implement user() method
    end
    
    include Model
    attr_accessor :pic, :pic_small, :pic_big, :name, :creator, :update_time, :description, :tagline, :venue, :host, :event_type, :nid, :location, :end_time, :start_time, :event_subtype

    id_is :eid
  end
end
