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
    def get_app_properties(properties)
      properties = properties.to_json if properties.respond_to?(:to_json)      
      json = @session.post('facebook.admin.getAppProperties', :properties => properties)
      array_of_hashes = JSON.parse(json)
      @properties = ApplicationProperties.from_array_of_hashes(array_of_hashes)
    end    
  end
end