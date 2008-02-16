module Facebooker
  class Admin
    def initialize(session)
      @session = session
    end
    
    # ** BETA ***
    # +properties+: Hash of properties you want to set
    def set_app_properties(properties)
      properties.respond_to?(:to_json) ? properties.to_json : properties
      (@session.post 'facebook.admin.setAppProperties', :properties => properties) == '1'
    end
    
    # ** BETA ***
    def get_app_properties(*properties)
      json = @session.post('facebook.admin.getAppProperties', :properties => properties.to_json)
      hash = JSON.parse(CGI.unescapeHTML(json))
      @properties = ApplicationProperties.from_hash(hash)
    end
  
    # Integration points include :notifications_per_day, :requests_per_day
    def get_allocation(integration_point)
      @session.post('facebook.admin.getAllocation', :integration_point_name => integration_point.to_s).to_i
    end    
  end
end