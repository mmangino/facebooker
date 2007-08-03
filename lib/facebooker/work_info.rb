module Facebooker
  class WorkInfo
    include Model
    attr_accessor :end_date, :start_date, :company_name, :description, :position, :location
    def location=(location)
      @location = location.kind_of?(Hash) ? Location.from_hash(location) : location
    end
  end
end