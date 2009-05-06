require 'facebooker/model'
module Facebooker
  class StreamPost
    include Model
    populating_attr_accessor :message, :permalink, :created_time, :updated_time
    attr_accessor :actor, :viewer
    
    def created_time=(val)
      @created_time = convert_time_value(val)
    end
    def updated_time=(val)
      @updated_time = convert_time_value(val)
    end
    
    def convert_time_value(val)
      val.is_a?(Numeric) || val.is_a?(String) ? Time.at(val.to_i) : val
    end
  end
end