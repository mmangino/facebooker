begin
  require 'curb'
  Facebooker.use_curl = true
rescue LoadError
  $stderr.puts "Curb not found. Using Net::HTTP."
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
      service_url = url(params.delete(:base))
      result = post_multipart_form(service_url, params)
      Parser.parse(params[:method], result)
    end
    
    private
    def url(base = nil)
      base ||= @api_base
      URI.parse('http://'+ base + @api_path)
    end
    
    # Net::HTTP::MultipartPostFile
    def multipart_post_file?(object)
      object.respond_to?(:content_type) &&
      object.respond_to?(:data) &&
      object.respond_to?(:filename)
    end
    
    def to_curb_params(params)
      parray = []
      params.each_pair do |k,v|
        if multipart_post_file?(v)
          # Curl doesn't like blank field names
          field = Curl::PostField.file((k.blank? ? 'xxx' : k.to_s), nil, File.basename(v.filename))
          field.content_type = v.content_type
          field.content = v.data
          parray << field
        else
          parray << Curl::PostField.content(k.to_s, v.to_s)
        end
      end
      parray
    end
  end
end