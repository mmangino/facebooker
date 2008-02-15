require 'facebooker/model'
module Facebooker
  ##
  # A simple representation of a photo album.
  class Album
    include Model
    attr_accessor :aid, :cover_pid, :owner, :name, :created,
                  :modified, :description, :location, :link, :size

  end
end