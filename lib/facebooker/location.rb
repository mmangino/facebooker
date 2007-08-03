module Facebooker
  class Location
    include Model
    attr_accessor :city, :zip, :country, :state
  end
end