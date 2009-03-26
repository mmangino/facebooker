module ::ActionController
  class Base
    def self.inherited_with_facebooker(subclass)
      inherited_without_facebooker(subclass)
      if subclass.to_s == "ApplicationController"
        subclass.send(:include,Facebooker::Rails::Controller) 
        subclass.helper Facebooker::Rails::Helpers
      end
    end
    class << self
      alias_method_chain :inherited, :facebooker
    end
  end
end


# When making get requests, Facebook sends fb_sig parameters both in the query string
# and also in the post body. We want to ignore the query string ones because they are one
# request out of date
# We only do thise when there are POST parameters so that IFrame linkage still works
if Rails.version < '2.3'
  class ActionController::AbstractRequest
    def query_parameters_with_facebooker
      if request_parameters.blank?
        query_parameters_without_facebooker
      else
        (query_parameters_without_facebooker||{}).reject {|key,value| key.to_s =~ /^fb_sig/}
      end
    end
  
    alias_method_chain :query_parameters, :facebooker
  end
else
  class ActionController::Request
    def query_parameters_with_facebooker
      if request_parameters.blank?
        query_parameters_without_facebooker
      else
        (query_parameters_without_facebooker||{}).reject {|key,value| key.to_s =~ /^fb_sig/}
      end
    end
  
    alias_method_chain :query_parameters, :facebooker
  end
end

Mime::Type.register_alias "text/html", :fbml
Mime::Type.register_alias "text/javascript", :fbjs