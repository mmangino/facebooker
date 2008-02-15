require 'facebooker/model'
module Facebooker
  ##
  # Represents a user's affiliation, for example, which educational institutions
  # the user is associated with.
  class Affiliation
    include Model
    attr_accessor :name, :status, :type, :year, :nid
  end
end