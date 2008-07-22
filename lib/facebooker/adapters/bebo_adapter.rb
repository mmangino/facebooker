module Facebooker
  class BeboAdapter < AdapterBase
      
    def canvas_server_base
      "apps.bebo.com"
    end
      
    def api_server_base
      'apps.bebo.com'
    end
    
    def api_rest_path
      "/restserver.php"
    end
      
    def is_for?(application_context)
      application_context == :bebo
    end
       
    def www_server_base_url
      "www.bebo.com"
    end

       
    def login_url_base
      "http://#{www_server_base_url}/SignIn.jsp?ApiKey=#{api_key}&v=1.0"
    end

    def install_url_base
      "http://#{www_server_base_url}/c/apps/add?ApiKey=#{api_key}&v=1.0"
    end
  end
end

# Things that don't actually work as expected in BEBO
Facebooker::PublishTemplatizedAction
module Facebooker
   class User
    def set_profile_fbml_with_bebo_adapter(profile_fbml, mobile_fbml, profile_action_fbml, profile_main = nil)
      if(Facebooker.is_for?(:bebo))
        self.session.post('facebook.profile.setFBML', :uid => @id, :markup => profile_fbml)
      else
        set_profile_fbml_without_bebo_adapter(profile_fbml,mobile_fbml, profile_action_fbml, profile_main)
      end
    end
    alias_method_chain :set_profile_fbml, :bebo_adapter
    
    private
    
    BEBO_FIELDS = FIELDS - [:meeting_sex, :wall_count, :meeting_for]
    def collect(fields)
      if(Facebooker.is_for?(:bebo) )
         BEBO_FIELDS.reject{|field_name| !fields.empty? && !fields.include?(field_name)}.join(',')
      else
         FIELDS.reject{|field_name| !fields.empty? && !fields.include?(field_name)}.join(',')
      end
    end   
  end
  
  
   class PublishTemplatizedAction < Parser#:nodoc:
    class <<self
     def process_with_bebo_adapter(data)
       if(Facebooker.is_for?(:bebo))
       element('feed_publishTemplatizedAction_response', data).text_value
       else
         process_without_bebo_adapter(data)
       end
      end
      alias_method_chain :process, :bebo_adapter
    end
  end
end