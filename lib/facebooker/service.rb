begin
  require 'curb'
  Facebooker.use_curl = true
rescue Exception=>e
  puts e
  require 'net/http'
end
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
      Parser.parse(params[:method], post_form(url,params) )
    rescue Errno::ECONNRESET, EOFError
      if attempt == 0
        attempt += 1
        retry
      end
    end
    
    def post_form(url,params)
      if Facebooker.use_curl?
        post_form_with_curl(url,params)
      else
        post_form_with_net_http(url,params)
      end
    end
    
    def post_form_with_net_http(url,params)
      Net::HTTP.post_form(url, params)
    end
    
    def post_form_with_curl(url,params,multipart=false)
      response = Curl::Easy.http_post(url.to_s, *to_curb_params(params)) do |c|
        c.multipart_form_post = multipart
        c.timeout = Facebooker.timeout 
      end
      response.body_str
    end
    
    def post_multipart_form(url,params)
      if Facebooker.use_curl?
        post_form_with_curl(url,params,true)
      else
        post_multipart_form_with_net_http(url,params)
      end
    end
    
    def post_multipart_form_with_net_http(url,params)
      Net::HTTP.post_multipart_form(url, params)
    end
    
    def post_file(params)
      Parser.parse(params[:method], post_multipart_form(url, params))
    end
    
    private
    def url
      URI.parse('http://'+ @api_base + @api_path)
    end
    
    def multipart_post_file?(object)
      object.respond_to?(:content_type) &&
      object.respond_to?(:data) &&
      object.respond_to?(:filename)
    end
    
    def to_curb_params(params)
      parray = []
      params.each_pair do |k,v|
        parray << (multipart_post_file?(v) ? Curl::PostField.file((k.nil? ? nil : k.to_s), v.filename.to_s) : Curl::PostField.content(k.to_s, v.to_s).to_s)
      end
      parray
    end
  end
end