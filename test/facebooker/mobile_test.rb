require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class Facebooker::MobileTest < Test::Unit::TestCase
  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
    @user = Facebooker::User.new(1234, @session)
    Facebooker.use_curl=false
  end
  
  def test_can_send
    expect_http_posts_with_responses(example_can_send_xml)
    assert(@session.mobile.can_send(@user))
  end

  def test_send
    expect_http_posts_with_responses(example_send_xml)
    assert(@session.mobile.send(@user, "Some sort of message"))    
  end

private
  def example_can_send_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <sms_canSend_response
      xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://api.facebook.com/1.0/http://api.facebook.com/1.0/facebook.xsd">
      0
    </sms_canSend_response>
    XML
  end
  
  def example_send_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <sms_send_response
      xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="http://api.facebook.com/1.0/http://api.facebook.com/1.0/facebook.xsd">
      0
    </sms_send_response>
    XML
  end
  
end
