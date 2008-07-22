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
  
  def test_cast_to_friend_list_id_with_nil
    assert_nil @user.cast_to_friend_list_id(nil)
  end
  def test_cast_to_friend_list_id_with_integer
    assert_equal 14,@user.cast_to_friend_list_id(14)
  end
  def test_cast_to_friend_list_id_with_string
    @user.expects(:friend_lists).returns([Facebooker::FriendList.new(:flid=>199,:name=>"Work")])
    assert_equal 199,@user.cast_to_friend_list_id("Work")
  end
  def test_cast_to_friend_list_id_with_friend_list
    assert_equal 199,@user.cast_to_friend_list_id(Facebooker::FriendList.new(:flid=>199,:name=>"Work"))
  end
  
  def test_cast_to_friend_list_id_with_invalid_string_raises
    @user.expects(:friend_lists).returns([Facebooker::FriendList.new(:flid=>1,:name=>"Not Picked")])
    assert_nil @user.cast_to_friend_list_id("Something")
    fail("No exception raised, Expected Facebooker::Session::InvalidFriendList")
  rescue   Facebooker::Session::InvalidFriendList
    nil
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
  
  def test_can_set_profile_main
    @user.expects(:set_profile_fbml).with(nil,nil,nil,"test")
    @user.profile_main="test"
  end
  
  def test_can_call_set_profile_fbml
    @session.expects(:post).with('facebook.profile.setFBML', :uid=>1234,:profile=>"profile",:profile_action=>"action",:mobile_profile=>"mobile")
    @user.set_profile_fbml("profile","mobile","action")
  end
  
  def test_can_call_set_profile_fbml_with_profile_main
    @session.expects(:post).with('facebook.profile.setFBML', :uid=>1234,:profile=>"profile",:profile_action=>"action",:mobile_profile=>"mobile", :profile_main => 'profile_main')
    @user.set_profile_fbml("profile","mobile","action",'profile_main')
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
  
  def test_can_set_status_with_string
    @session.expects(:post).with('facebook.users.setStatus', :status=>"my status",:status_includes_verb=>1)
    @user.status="my status"
  end
  
  def test_get_events
    @user = Facebooker::User.new(9507801, @session)
    expect_http_posts_with_responses(example_events_get_xml)
    events = @user.events
    assert_equal "29511517904", events.first.eid
  end
  
  def test_can_get_events
    @user.expects(:events)
    @user.events
  end
  
  def test_to_s
    assert_equal("1234",@user.to_s)
  end
  
  def test_equality
    assert_equal @user, @user.dup
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
  
  def example_events_get_xml
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
    <events_get_response xmlns=\"http://api.facebook.com/1.0/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd\" list=\"true\">
      <event>
        <eid>29511517904</eid>
        <name>PUMA SALE</name>
        <tagline/>
        <nid>0</nid>
        <pic>http://profile.ak.facebook.com/object3/370/66/s29511517904_6952.jpg</pic>
        <pic_big>http://profile.ak.facebook.com/object3/370/66/n29511517904_6952.jpg</pic_big>
        <pic_small>http://profile.ak.facebook.com/object3/370/66/t29511517904_6952.jpg</pic_small>
        <host>PUMA</host>
        <description>PUMA SALE</description>
        <event_type>Education</event_type>
        <event_subtype>Study Group</event_subtype>
        <start_time>1212166800</start_time>
        <end_time>1212364800</end_time>
        <creator>1234261165</creator>
        <update_time>1209768148</update_time>
        <location>PUMA LOT</location>
        <venue>
          <street>5 LYBERTY WAY</street>
          <city>Westford</city>
          <state>Massachusetts</state>
          <country>United States</country>
          <latitude>42.5792</latitude>
          <longitude>-71.4383</longitude>
        </venue>
      </event>
    </events_get_response>"
  end
end