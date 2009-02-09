require 'facebooker/model'
module Facebooker
  class Video
    include Model
    attr_accessor :vid, :owner, :title,
                  :link, :description, :created,
                  :story_fbid
  end
end