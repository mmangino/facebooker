module Facebooker

  class ApplicationRestrictions
    include Model
    FIELDS = [ :age, :location, :age_distribution, :type ]

    attr_accessor(*FIELDS)

  end
end
