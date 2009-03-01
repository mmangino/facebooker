require 'facebooker/session'

module Facebooker
  class MockSession < Session
    def secured?
      true
    end

    def secure!
      @uid = 1
      true
    end
 
    def service
      @service ||= MockService.new(Facebooker.api_server_base, Facebooker.api_rest_path, @api_key)
    end
  end
end