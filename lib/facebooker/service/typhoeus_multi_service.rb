class Facebooker::Service::TyphoeusMultiService <  Facebooker::Service::TyphoeusService
  
  def initialize
    @result_objects = []
  end
  
  def parse_results?
    false
  end
  
  #define a method that returns nothing
  define_remote_method :async_post,  :on_success => lambda {|r| puts "."}
  
  def perform_post(url,params)
    add_result(self.class.async_post(:base_uri=>url,:params=>params))
  end
  
  def add_result(obj)
    @result_objects << obj
  end
  
  def process
    # we need to access all objects to make sure the proxy has made the request
    @result_objects.each(&:nil?)
    @result_objects = []
  end
end