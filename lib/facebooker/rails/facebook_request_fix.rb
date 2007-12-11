module ::ActionController
  class AbstractRequest
    def request_method_with_facebooker
      if parameters[:fb_sig_request_method]=="GET" and parameters[:_method].blank?
        parameters[:_method]="GET"
      end
      request_method_without_facebooker
    end
    
    if new.methods.include?("request_method")
      alias_method_chain :request_method, :facebooker 
    end
  end
end