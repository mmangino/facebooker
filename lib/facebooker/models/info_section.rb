module Facebooker
  class InfoSection
    include Model
    attr_accessor :field, :items
    
    def to_json
      {:field => field, :items => items}.to_json
    end
  end
end