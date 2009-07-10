class Facebooker::Service::BaseService
  def parse_results?
    true
  end
  
  def post_params(params)
    post_params = {}
    params.each do |k,v|
      if Array === v || Hash === v
        post_params[k] = Facebooker.json_encode(v)       
      else
        post_params[k] = v
      end
    end
    post_params
  end
  
end