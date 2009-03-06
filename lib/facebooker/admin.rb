module Facebooker
  class Admin
    def initialize(session)
      @session = session
    end
    
    # ** BETA ***
    # +properties+: Hash of properties you want to set
    def set_app_properties(properties)
      properties = properties.respond_to?(:to_json) ? properties.to_json : properties
      (@session.post 'facebook.admin.setAppProperties', :properties => properties) == '1'
    end
    
    # ** BETA ***
    # +properties+: Hash of properties you want to view.
    def get_app_properties(*properties)
      json = @session.post('facebook.admin.getAppProperties', :properties => properties.to_json)
      hash = Facebooker.json_decode(CGI.unescapeHTML(json))
      @properties = ApplicationProperties.from_hash(hash)
    end
    
    # ** BETA ***
    # +restrictions+: Hash of restrictions you want to set.
    def set_restriction_info(restrictions)
      restrictions = restrictions.respond_to?(:to_json) ? restrictions.to_json : restrictions
      (@session.post 'facebook.admin.setRestrictionInfo', :restriction_str => restrictions) == '1'
    end
    
    # ** BETA ***
    def get_restriction_info(*restrictions)
      json = @session.post('facebook.admin.getRestrictionInfo')
      hash = Facebooker.json_decode(CGI.unescapeHTML(json))
      @restrictions = ApplicationRestrictions.from_hash(hash)
    end
  
    # Integration points include..
    #   :notifications_per_day, :requests_per_day, :emails_per_day, :email_disable_message_location
    def get_allocation(integration_point)
      @session.post('facebook.admin.getAllocation', :integration_point_name => integration_point.to_s).to_i
    end    
  end
end
