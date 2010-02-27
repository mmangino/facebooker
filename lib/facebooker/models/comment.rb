require 'facebooker/model'
module Facebooker
  ##
  # A simple representation of a comment
  class Comment
    include Model
    attr_accessor :xid, :fromid, :time, :text, :id
  end
end