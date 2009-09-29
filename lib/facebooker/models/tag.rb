require 'facebooker/model'
module Facebooker
  class Tag
    include Model
    attr_accessor :pid, :subject, :xcoord, :ycoord, :text, :created
    
    def coordinates
      [xcoord, ycoord]
    end
    
  end
end