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
    
    # News is an array of news items: http://wiki.developers.facebook.com/index.php/Dashboard.addGlobalNews
    def add_global_news(news, image=nil)
      params = {}
      params[:news] = news
      params[:image] = image if image
      @session.post('facebook.dashboard.addGlobalNews', params)
    end
    
    # currently bugged; returns all
    def get_global_news(news_ids=nil)
      params = {}
      params[:news_ids] = news_ids if news_ids
      @session.post('facebook.dashboard.getGlobalNews', params)
    end
    
    def clear_global_news(news_ids=nil)
      params = {}
      params[:news_ids] = news_ids if news_ids
      @session.post('facebook.dashboard.clearGlobalNews', params)
    end
    
  end
end