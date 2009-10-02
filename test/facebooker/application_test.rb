require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class Facebooker::ApplicationTest < Test::Unit::TestCase
  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
    Facebooker.use_curl=false
  end
  
  def test_can_get_public_info
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_get_public_info_xml).once.ordered(:posts)
    info = @session.application.get_public_info(:app_id => 2413267546)
    assert_equal '2413267546', info["app_id"]
    assert_equal 'ilike', info["canvas_name"]
  end

  private

  def example_get_public_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <application_getPublicInfo_response 
      xmlns="http://api.facebook.com/1.0/"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
      xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd"> 
      <app_id>2413267546</app_id> 
      <api_key>c756401cb800e295f21d723b7842ea83</api_key> 
      <canvas_name>ilike</canvas_name> 
      <display_name>iLike</display_name> 
      <icon_url>http://photos-c.ak.facebook.com/photos-ak-sctm/v43/130/2413267546/app_2_2413267546_6706.gif</icon_url> 
      <logo_url>http://photos-c.ak.facebook.com/photos-ak-sctm/v43/130/2413267546/app_1_2413267546_2324.gif</logo_url> 
      <developers list="true"/> 
      <company_name>iLike, inc</company_name> 
      <description>iLike lets you add music to your profile and find your favorite concerts (not to mention see who else is going!). Bonus: Use it to get free mp3’s that match your tastes and try to beat your friends at the Music Challenge.</description> 
      <daily_active_users>392008</daily_active_users> 
      <weekly_active_users>1341749</weekly_active_users> 
      <monthly_active_users>3922784</monthly_active_users> 
    </application_getPublicInfo_response>
    XML
  end
end
