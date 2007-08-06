require 'facebooker/model'
module Facebooker
  class Album
    include Model
    attr_accessor :aid, :cover_pid, :owner, :name, :created,
                  :modified, :description, :location, :link, :size

  end
end