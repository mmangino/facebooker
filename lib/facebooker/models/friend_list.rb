require 'facebooker/model'
module Facebooker
  ##
  # A simple representation of a friend list.
  class FriendList
    include Model
    attr_accessor :name

    id_is :flid

    # We need this to be an integer, so do the conversion
    def flid=(f)
      @flid= ( f.nil? ? nil : f.to_i)
    end
  end
end
