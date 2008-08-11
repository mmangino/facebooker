require 'net/http'
require 'facebooker/parser'
module Facebooker
  class Service
    def initialize(api_base, api_path, api_key)
      @api_base = api_base
      @api_path = api_path
      @api_key = api_key
    end
    
    # TODO: support ssl 
    def post(params)
      attempt = 0
      Parser.parse(params[:method], Net::HTTP.post_form(url, params))
    rescue Errno::ECONNRESET, EOFError
      if attempt == 0
        attempt += 1
        retry
      end
    end
    
    def post_file(params)
      Parser.parse(params[:method], Net::HTTP.post_multipart_form(url, params))
    end
    
    private
    def url
      URI.parse('http://'+ @api_base + @api_path)
    end
  end
end