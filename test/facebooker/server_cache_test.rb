require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class FacebookCacheTest < Test::Unit::TestCase
  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
    Facebooker.use_curl=false
  end
  
  def test_can_ask_facebook_to_store_fbml_in_a_named_reference
    expect_http_posts_with_responses(example_set_ref_handle_xml)
    assert(@session.server_cache.set_ref_handle('a_handle_name', '<h2>Some FBML</h2>'))
  end
  
  def test_can_ask_facebook_to_recache_content_stored_from_a_given_url
    expect_http_posts_with_responses(example_refresh_ref_url_xml)
    assert(@session.server_cache.refresh_ref_url('http://localhost/roflmao'))
  end

  def test_can_ask_facebook_to_recache_an_img
    expect_http_posts_with_responses(example_refresh_img_xml)
    assert(@session.server_cache.refresh_img_src('http://localhost/roflmao.jpg'))
  end
  
  private
    def example_set_ref_handle_xml
      <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <fbml_setRefHandle_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</fbml_setRefHandle_response>      
      XML
    end
    
    def example_refresh_ref_url_xml
      <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <fbml_refreshRefUrl_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</fbml_refreshRefUrl_response>      
      XML
    end
    def example_refresh_img_xml
      <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <fbml_refreshImgSrc_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</fbml_refreshImgSrc_response>      
      XML
    end
end