module Facebooker
  class InfoItem
    include Model
    attr_accessor :label, :image, :description, :link, :sublabel
    
    def to_json
      {:label => label, :image => image, :description => description, :link => link, :sublabel => sublabel}.to_json
    end
  end
end