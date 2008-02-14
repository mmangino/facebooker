require File.dirname(__FILE__) + '/test_helper.rb'

class FacebookAdminTest < Test::Unit::TestCase
  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
  end
  
  def test_can_ask_facebook_to_set_app_properties
    expect_http_posts_with_responses(example_set_properties_xml)
    properties = { :application_name => "Video Jukebox", :dev_mode => 0 }    
    assert(@session.admin.set_app_properties(properties))
  end
    
  def test_can_ask_facebook_to_get_app_properties
    expect_http_posts_with_responses(example_get_properties_xml)
    properties = [ :application_name, :dev_mode ]
    assert(@session.admin.get_app_properties(properties))
  end
  
  def test_can_get_properties
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_get_properties_xml).once.ordered(:posts)
    p = @session.admin.get_app_properties(:application_name, :dev_mode)
    assert_equal 'Trunc', p.application_name
    assert_equal 0, p.dev_mode
  end

  private
  def example_set_properties_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <data_setAppProperties_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</data_setAppProperties_response>
    XML
  end

  def example_get_properties_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <admin_getAppProperties_response
      xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://api.facebook.com/1.0/http://api.facebook.com/1.0/facebook.xsd">
        [{"application_name": "Trunc"}, {"dev_mode": 0}]
    </admin_getAppProperties_response>
    XML
  end
end