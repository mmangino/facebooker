module Facebooker
  class EducationInfo
    class HighschoolInfo
      include Model
      attr_accessor :hs1_id, :hs2_id, :grad_year, :hs1_name, :hs2_name
    end
    
    include Model
    attr_accessor :concentrations, :name, :year, :degree
  end
end