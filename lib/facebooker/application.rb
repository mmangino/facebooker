module Facebooker
  class Application
    def initialize(session)
      @session = session
    end
    
    # +properties+: Hash of properties of the desired application. Specify exactly one of: application_id, application_api_key or application_canvas_name 
    # eg: application.get_public_info(:application_canvas_name => ENV['FACEBOOKER_RELATIVE_URL_ROOT'])
    def get_public_info(properties)
      (@session.post 'facebook.application.getPublicInfo', properties)
    end
  end
end