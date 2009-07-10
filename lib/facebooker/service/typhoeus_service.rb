require 'typhoeus'
class Facebooker::Service::TyphoeusService < Facebooker::Service::BaseService
  include Typhoeus
  def post_form(url,params)
    perform_post(url.to_s,post_params(params))
  end
  
  def perform_post(url,params)
    self.class.post(url,:params=>post_params)
  end
  
  def post_multipart_form(url,params)
    raise "Multipart not supported on Typhoeus"
  end
  
  
end