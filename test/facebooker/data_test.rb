require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class Facebooker::DataTest < Test::Unit::TestCase
  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
    #make sure we use net::http since that's what the tests expect
    Facebooker.use_curl=false
  end

  def test_can_ask_facebook_to_set_a_cookies
    expect_http_posts_with_responses(example_set_cookie_xml)
    assert(@session.data.set_cookie(12345, 'name', 'value'))
  end

  def test_can_ask_facebook_to_get_cookies
    expect_http_posts_with_responses(example_get_cookies_xml)
    assert(@session.data.get_cookies(12345))
  end

  def test_can_get_cookies_for_user
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_get_cookies_xml).once.ordered(:posts)
    cookies = @session.data.get_cookies(508508326)
    assert_equal 'Foo', cookies.first.name
    assert_equal 'Bar', cookies.first.value
  end

  def test_can_ask_facebook_to_set_a_preference
    expect_http_posts_with_responses(example_set_preference_xml)
    assert(@session.data.set_preference(0, 'hello'))
  end

  def test_can_ask_facebook_to_get_preference
    expect_http_posts_with_responses(example_get_preference_xml)
    assert(@session.data.get_preference(0))
  end

  def test_can_get_preference
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_get_preference_xml).once.ordered(:posts)
    assert_equal 'hello', @session.data.get_preference(0)
  end

  private
  def example_set_cookie_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <data_setCookie_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</data_setCookie_response>
    XML
  end

  def example_get_cookies_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <data_getCookie_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <cookies>
        <uid>508508326</uid>
        <name>Foo</name>
        <value>Bar</value>
        <expires>0</expires>
        <path>/tmp/</path>
      </cookies>
    </data_getCookie_response>
    XML
  end

  def example_set_preference_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <data_setUserPreference_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd"/>
    XML
  end

  def example_get_preference_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <data_getUserPreference_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      hello
    </data_getUserPreference_response>
    XML
  end
end
