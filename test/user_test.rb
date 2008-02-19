require File.dirname(__FILE__) + '/test_helper.rb'
require 'rubygems'
require 'flexmock/test_unit'

class UserTest < Test::Unit::TestCase
  
  def setup
    @session = Facebooker::Session.create('apikey', 'secretkey')
    @user = Facebooker::User.new(1234, @session)
    @other_user = Facebooker::User.new(4321, @session)
    @user.friends = [@other_user]
  end
  
  def test_can_ask_user_if_he_or_she_is_friends_with_another_user
    assert(@user.friends_with?(@other_user))
  end
  
  def test_can_ask_user_if_he_or_she_is_friends_with_another_user_by_user_id
    assert(@user.friends_with?(@other_user.id))
  end
  
  def test_can_create_from_current_session
    Facebooker::Session.expects(:current).returns("current")
    user=Facebooker::User.new(1)
    assert_equal("current",user.session)
  end
  
  def test_can_set_mobile_fbml
    @user.expects(:set_profile_fbml).with(nil,"test",nil)
    @user.mobile_fbml="test"
  end
  def test_can_set_profile_action
    @user.expects(:set_profile_fbml).with(nil,nil,"test")
    @user.profile_action="test"
  end
  def test_can_set_profile_fbml
    @user.expects(:set_profile_fbml).with("test",nil,nil)
    @user.profile_fbml="test"
  end
  
  def test_can_call_set_profile_fbml
    @session.expects(:post).with('facebook.profile.setFBML', :uid=>1234,:profile=>"profile",:profile_action=>"action",:mobile_profile=>"mobile")
    @user.set_profile_fbml("profile","mobile","action")
  end
  
  def test_can_get_profile_photos
    @user.expects(:profile_photos)
    @user.profile_photos
  end
  
  def test_can_set_cookie
    @user.expects(:set_cookie).with('name', 'value')
    @user.set_cookie('name', 'value')
  end
  
  def test_can_get_cookies
    @user.expects(:get_cookies).with('name')
    @user.get_cookies('name')
  end
  
  def test_get_profile_photos
    @user = Facebooker::User.new(548871286, @session)
    expect_http_posts_with_responses(example_profile_photos_get_xml)    
    photos = @user.profile_photos
    assert_equal "2357384227378429949", photos.first.aid
  end
  
  def test_can_send_email
    @user.expects(:send_email).with("subject", "body text")
    @user.send_email("subject", "body text")
    
    @user.expects(:send_email).with("subject", nil, "body fbml")
    @user.send_email("subject", nil, "body fbml")
  end
  
  def test_to_s
    assert_equal("1234",@user.to_s)
  end
  
  private
  def example_profile_photos_get_xml
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <photos_get_response xmlns=\"http://api.facebook.com/1.0/\"
      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
      xsi:schemaLocation=\"http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd\" list=\"true\">
       <photo>
         <pid>34585991612804</pid>
         <aid>2357384227378429949</aid>
         <owner>1240077</owner>
         <src>http://ip002.facebook.com/v11/135/18/8055/s1240077_30043524_2020.jpg</src>
         <src_big>http://ip002.facebook.com/v11/135/18/8055/n1240077_30043524_2020.jpg</src_big>
         <src_small>http://ip002.facebook.com/v11/135/18/8055/t1240077_30043524_2020.jpg</src_small>
         <link>http://www.facebook.com/photo.php?pid=30043524&id=8055</link>
         <caption>From The Deathmatch (Trailer) (1999)</caption>
         <created>1132553361</created>
       </photo>
       <photo>
         <pid>34585991612805</pid>
         <aid>2357384227378429949</aid>
         <owner>1240077</owner>
         <src>http://ip002.facebook.com/v11/135/18/8055/s1240077_30043525_2184.jpg</src>
         <src_big>http://ip002.facebook.com/v11/135/18/8055/n1240077_30043525_2184.jpg</src_big>
         <src_small>http://ip002.facebook.com/v11/135/18/8055/t1240077_30043525_2184.jpg</src_small>
         <link>http://www.facebook.com/photo.php?pid=30043525&id=8055</link>
         <caption>Mexico City, back cover of the CYHS Student Underground 1999.</caption>
         <created>1132553362</created>
       </photo>
    </photos_get_response>"
  end
  
end