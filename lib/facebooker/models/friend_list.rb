require 'facebooker/model'
module Facebooker
  ##
  # A simple representation of a photo album.
  class FriendList
    include Model
    attr_accessor :flid, :name
    
    # We need this to be an integer, so do the conversion
    def flid=(f)
      @flid= ( f.nil? ? nil : f.to_i)
    end
  end
end