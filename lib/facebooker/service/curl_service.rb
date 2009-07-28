require 'curb'
Facebooker.use_curl = true
class Facebooker::Service::CurlService < Facebooker::Service::BaseService
  def post_form(url,params,multipart=false)
    curl = Curl::Easy.new(url.to_s) do |c|
      c.multipart_form_post = multipart
      c.timeout = Facebooker.timeout
    end
    curl.http_post(*to_curb_params(params)) 
    curl.body_str
  end
  
  def post_multipart_form(url,params)
    post_form(url,params,true)
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
        parray << Curl::PostField.content(
          k.to_s,
          (Array === v || Hash===v) ? Facebooker.json_encode(v) : v.to_s
        )
      end
    end
    parray
  end
  
end
  