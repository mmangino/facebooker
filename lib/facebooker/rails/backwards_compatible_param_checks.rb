module Facebooker::Rails::BackwardsCompatibleParamChecks

    def one_or_true( value )
      case value
        when String then
          value == "1"
        when Numeric then
          value.to_f == 1.0
        when TrueClass then
          true
        else
          false
      end
    end

    def zero_or_false( value )
      case value
        when String then
          value.empty? || value == "0"
        when Numeric then
          value.to_f == 0.0
        when FalseClass then
          true
        when NilClass then
          true
        else
          false
      end
    end

end
