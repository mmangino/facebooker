require 'facebooker/model'
module Facebooker
  
  ##
  # A simple representation of a cookie.
  class Cookie
    include Model
    attr_accessor :uid, :name, :value, :expires, :path
  end
end