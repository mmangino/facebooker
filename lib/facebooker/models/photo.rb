require 'facebooker/model'
module Facebooker
  class Photo
    include Model
    attr_accessor :aid, :owner, :title,
                  :link, :caption, :created,
                  :src, :src_big, :src_small,
                  :story_fbid

    id_is :pid
    
    #override the generated method for id_is to use a string
    def pid=(val)
      @pid = val
    end
    
    alias :id= :pid=
  end
end
