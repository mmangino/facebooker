module Facebooker
  class InfoItem
    include Model
    attr_accessor :label, :image,:description, :link
    
    def to_json
      {:label=>label,:image=>image,:description=>description,:link=>link}.to_json
    end
  end
end