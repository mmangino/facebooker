module Facebooker
  class Application
    def initialize(session)
      @session = session
    end
    
    # +properties+: Hash of properties of the desired application. Specify exactly one of: application_id, application_api_key or application_canvas_name
    def get_public_info(properties)
      properties = properties.respond_to?(:to_json) ? properties.to_json : properties
      (@session.post 'facebook.application.getPublicInfo', :properties => properties)
    end
  end
end
