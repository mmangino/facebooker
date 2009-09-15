require 'facebooker/model'
module Facebooker
  class FamilyRelativeInfo
    include Model
    attr_accessor :relationship, :uid, :name, :birthday
  end
end