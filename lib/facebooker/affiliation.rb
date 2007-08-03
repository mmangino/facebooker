require 'facebooker/model'
module Facebooker
  class Affiliation
    include Model
    attr_accessor :name, :status, :type, :year, :nid
  end
end