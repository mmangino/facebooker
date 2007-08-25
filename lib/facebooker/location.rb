module Facebooker
  ##
  # Representation of Location used in all places where a Location is specified.
  class Location
    include Model
    attr_accessor :city, :zip, :country, :state
  end
end