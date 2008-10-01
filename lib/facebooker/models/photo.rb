require 'facebooker/model'
module Facebooker
  class Photo
    include Model
    attr_accessor :pid, :aid, :owner, :title,
                  :link, :caption, :created,
                  :src, :src_big, :src_small,
                  :story_fbid
  end
end