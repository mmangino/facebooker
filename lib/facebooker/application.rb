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
    
    # facebook_session.application.add_global_news [{ :message => 'Hi all users', :action_link => { :text => "Hi application", :href => 'http://facebook.er/' }}], 'http://facebook.er/icon.png'
    def add_global_news(news, image=nil)
      params = {}
      params[:news] = news
      params[:image] = image if image
      @session.post('facebook.dashboard.addGlobalNews', params)
    end
    
    # currently bugged on Facebook; returns all
    # facebook_session.application.get_global_news '310354202543'
    def get_global_news(*news_ids)
      params = {}
      params[:news_ids] = news_ids.flatten if news_ids
      @session.post('facebook.dashboard.getGlobalNews', params)
    end
    
    # facebook_session.application.clear_global_news '310354202543'
    def clear_global_news(*news_ids)
      params = {}
      params[:news_ids] = news_ids.flatten if news_ids
      @session.post('facebook.dashboard.clearGlobalNews', params)
    end
    
  end
end