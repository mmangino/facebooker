require File.dirname(__FILE__) + '/test_helper.rb'

class TestFacebooker < Test::Unit::TestCase

  def setup
    @api_key = "95a71599e8293s66f1f0a6f4aeab3df7"
    @secret_key = "3e4du8eea435d8e205a6c9b5d095bed1"
    @session = Facebooker::Session.create(@api_key, @secret_key)
    @desktop_session = Facebooker::Session::Desktop.create(@api_key, @secret_key)
    @service = Facebooker::Service.new('http://apibase.com', '/api/path', @api_key)
    @desktop_session.instance_variable_set("@service", @service)
  end
  
  def test_session_must_be_created_from_api_key_and_secret_key
    assert_kind_of(Facebooker::Session, @session)
  end
  
  def test_session_can_tell_you_its_login_url
    assert_not_nil(@session.login_url)
    assert_equal("http://www.facebook.com/login.php?api_key=#{@api_key}&v=1.0", @session.login_url)
  end
  
  def test_desktop_session_returns_auth_toke_as_part_of_login_url
    @service = flexmock(@service).should_receive(:post).at_least.once.and_return(123)
    assert_kind_of(Facebooker::Session::Desktop, @desktop_session)
    assert_match(/auth_token=[a-z0-9A-Z]/, @desktop_session.login_url)
  end

  def test_service_posts_data_to_http_location
    flexmock(Net::HTTP).should_receive(:post_form).and_return(example_auth_token_xml)
    assert_equal("http://www.facebook.com/login.php?api_key=#{@api_key}&v=1.0&auth_token=3e4a22bb2f5ed75114b0fc9995ea85f1", @desktop_session.login_url)
  end

  def test_desktop_session_be_secured_and_activated_after_receiving_auth_token_and_logging_in
    establish_session
    assert_equal("5f34e11bfb97c762e439e6a5-8055", @session.instance_variable_get("@session_key"))
  end

  def test_desktop_session_uses_secret_api_key_for_hashing_until_user_authenticates
    assert_equal(@secret_key, @desktop_session.secret_for_method('facebook.auth.createToken'))
    establish_session(@desktop_session)
    assert_equal("ohairoflamao12345", @desktop_session.secret_for_method('anyNonAuthMethodName'))
  end

  def test_session_can_get_current_logged_in_user_id_and_will_cache
    establish_session
    flexmock(Net::HTTP).should_receive(:post_form).and_return(example_get_logged_in_user_xml)
    assert_equal(8055, @session.user.id)
  end

  def test_can_get_current_users_friends
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_friends_xml).once.ordered(:posts)
    assert_equal([222333, 1240079], @session.user.friends.map{|friend| friend.id})
  end
  
  def test_can_get_info_for_one_or_more_users
    friends = populate_session_friends
    friend = friends.detect{|f| f.id == 222333}
    assert_equal('This field perpetuates the glorification of the ego.  Also, it has a character limit.',
                 friend.about_me)  
    assert_equal('Facebook Developers', friend.affiliations.first.name)
    assert_equal('Friendship', friend.meeting_for.first)
    assert_equal('94303', friend.current_location.zip)
    assert_equal('York', friend.hometown_location.city)
    assert_equal('Harvard', friend.education_history.first.name)
    assert(friend.education_history.first.concentrations.include?("Computer Science"))
    assert_equal('Central York High School', friend.hs_info.hs1_name)
    assert_equal('female', friend.meeting_sex.first)
    assert_equal('I rule', friend.status.message)
  end

  def test_session_can_expire_on_server_and_client_handles_appropriately
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_session_expired_error_response).once.ordered(:posts)
    assert_raises(Facebooker::Session::SessionExpired) {
      @session.user.friends
    }
  end

  
  def test_can_publish_story_to_users_feed
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_publish_story_xml).once.ordered(:posts)
    assert_nothing_raised {
      assert(@session.user.publish_story((s = Facebooker::Feed::Story.new; s.title = 'o hai'; s.body = '4srsly'; s)))
    }
  end
  
  
  def test_can_publish_action_to_users_feed
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_publish_action_xml).once.ordered(:posts)
    assert_nothing_raised {
      assert(@session.user.publish_action((s = Facebooker::Feed::Action.new; s.title = 'o hai'; s.body = '4srsly'; s)))
    }
  end
  
  def test_can_get_notifications_for_logged_in_user
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_notifications_get_xml).once.ordered(:posts)
    assert_equal("1", @session.user.notifications.messages.unread)  
    assert_equal("0", @session.user.notifications.pokes.unread)    
    assert_equal("1", @session.user.notifications.shares.unread)        
  end
  
  def test_can_send_notifications
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_notifications_send_xml).once.ordered(:posts)
    assert_nothing_raised {
      user_ids = [123, 321]
      notification_fbml = "O HAI!!!"
      optional_email_fbml = "This would be in the email.  If this is not passed, facebook sends  no mailz!"
      @session.send_notification(user_ids, notification_fbml, optional_email_fbml)
    }
  end
  
  def test_should_get_albums_for_user
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_user_albums_xml).once.ordered(:posts)
    assert_equal('Summertime is Best', @session.user.albums.first.name)
    assert_equal(2, @session.user.albums.size)
  end
 
  def test_can_find_friends_who_have_installed_app
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_app_users_xml).once.ordered(:posts)
    assert_equal(2, @session.user.friends_with_this_app.size)
    assert_equal([222333, 1240079], @session.user.friends_with_this_app.map{|f| f.id})
  end
  
  def test_when_marshaling_a_session_object_only_enough_data_to_stay_authenticated_is_stored
    populate_session_friends
    assert_equal(2, @session.user.friends.size)
    reloaded_session = Marshal.load(Marshal.dump(@session))
    %w(@session_key @uid @expires @secret_from_session @auth_token).each do |iv_name|
      assert_not_nil(reloaded_session.instance_variable_get(iv_name))
    end
    assert_nil(reloaded_session.user.instance_variable_get("@friends"))
  end
  
  
  def test_sessions_can_be_infinite_or_can_expire
    establish_session
    assert(@session.expired?, "Session with expiry time #{@session.instance_variable_get('@expires')} occurred in the past and should be expired.")
    @session.instance_variable_set("@expires", 0)
    assert(@session.infinite?)
    assert(!@session.expired?)
  end
  
  def test_session_can_tell_you_if_it_has_been_secured
    mock = flexmock(Net::HTTP).should_receive(:post_form).and_return(example_auth_token_xml).once.ordered(:posts)
    mock.should_receive(:post_form).and_return(example_get_session_xml.sub(/1173309298/, (Time.now + 60).to_i.to_s)).once.ordered(:posts)
    @session.secure!    
    assert(@session.secured?)
  end
  
  def test_should_get_albums_by_album_ids
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_user_albums_xml).once.ordered(:posts)
    assert_equal('Summertime is Best', @session.get_albums(:aids => [97503428432802022, 97503428432797817] ).first.name)
  end
  
  def test_should_create_album
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_new_album_xml).once.ordered(:posts)
    assert_equal "My Empty Album", @session.user.create_album(:name => "My Empty Album", :location => "Limboland").name
  end  
  
  private
  def establish_session(session = @session)
    mock = flexmock(Net::HTTP).should_receive(:post_form).and_return(example_auth_token_xml).once.ordered(:posts)
    mock.should_receive(:post_form).and_return(example_get_session_xml).once.ordered(:posts)
    session.secure!    
    mock
  end
  
  
  def populate_session_friends
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_friends_xml).once.ordered(:posts)
    mock_http.should_receive(:post_form).and_return(example_user_info_xml).once.ordered(:posts)
    @session.user.friends!    
  end
  
  def sample_args_to_post
    {:method=>"facebook.auth.createToken", :sig=>"18b3dc4f5258a63c0ad641eebd3e3930"}
  end  
  
  def example_notifications_send_xml
    <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<notifications_send_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">http://www.facebook.com/send_email.php?from=211031&id=52</notifications_send_response>
    XML
  end
  
  def example_notifications_get_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <notifications_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <messages>
        <unread>1</unread>
        <most_recent>1170644932</most_recent>
      </messages>
      <pokes>
        <unread>0</unread>
        <most_recent>0</most_recent>
      </pokes>
      <shares>
        <unread>1</unread>
        <most_recent>1170657686</most_recent>
      </shares>
      <friend_requests list="true">
        <uid>2231342839</uid>
        <uid>2231511925</uid>
        <uid>2239284527</uid>
      </friend_requests>
      <group_invites list="true"/>
      <event_invites list="true"/>
    </notifications_get_response>    
    XML
  end
  
  def example_publish_story_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_publishStoryToUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</feed_publishStoryToUser_response>    
    XML
  end
  
  def example_publish_action_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <feed_publishActionOfUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">1</feed_publishActionOfUser_response>    
    XML
  end
    
  def example_user_info_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_getInfo_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <user>
        <uid>222333</uid>
        <about_me>This field perpetuates the glorification of the ego.  Also, it has a character limit.</about_me>
        <activities>Here: facebook, etc. There: Glee Club, a capella, teaching.</activities>
        <affiliations list="true">
          <affiliation>
            <nid>50453093</nid>
            <name>Facebook Developers</name>
            <type>work</type>
            <status/>
            <year/>
          </affiliation>
        </affiliations> 
        <birthday>November 3</birthday>
        <books>The Brothers K, GEB, Ken Wilber, Zen and the Art, Fitzgerald, The Emporer's New Mind, The Wonderful Story of Henry Sugar</books>
        <current_location>
          <city>Palo Alto</city>
          <state>CA</state>
          <country>United States</country>
          <zip>94303</zip>
        </current_location>
        <education_history list="true">
          <education_info>
            <name>Harvard</name>
            <year>2003</year>
            <concentrations list="true">
              <concentration>Applied Mathematics</concentration>
              <concentration>Computer Science</concentration>
            </concentrations>
          </education_info>
        </education_history>
        <first_name>Dave</first_name>
         <hometown_location>
           <city>York</city>
           <state>PA</state>
           <country>United States</country>
           <zip>0</zip>
         </hometown_location>
         <hs_info>
           <hs1_name>Central York High School</hs1_name>
           <hs2_name/>
           <grad_year>1999</grad_year>
           <hs1_id>21846</hs1_id>
           <hs2_id>0</hs2_id>
         </hs_info>
         <is_app_user>1</is_app_user>
         <has_added_app>1</has_added_app>
         <interests>coffee, computers, the funny, architecture, code breaking,snowboarding, philosophy, soccer, talking to strangers</interests>
         <last_name>Fetterman</last_name>
         <meeting_for list="true">
           <seeking>Friendship</seeking>
         </meeting_for>
         <meeting_sex list="true">
           <sex>female</sex>
         </meeting_sex>
         <movies>Tommy Boy, Billy Madison, Fight Club, Dirty Work, Meet the Parents, My Blue Heaven, Office Space </movies>
         <music>New Found Glory, Daft Punk, Weezer, The Crystal Method, Rage, the KLF, Green Day, Live, Coldplay, Panic at the Disco, Family Force 5</music>
         <name>Dave Fetterman</name>
         <notes_count>0</notes_count>
         <pic>http://photos-055.facebook.com/ip007/profile3/1271/65/s8055_39735.jpg</pic>
         <pic_big>http://photos-055.facebook.com/ip007/profile3/1271/65/n8055_39735.jpg</pic_big>
         <pic_small>http://photos-055.facebook.com/ip007/profile3/1271/65/t8055_39735.jpg</pic_small>
         <pic_square>http://photos-055.facebook.com/ip007/profile3/1271/65/q8055_39735.jpg</pic_square>
         <political>Moderate</political>
         <profile_update_time>1170414620</profile_update_time>
         <quotes/>
         <relationship_status>In a Relationship</relationship_status>
         <religion/>
         <sex>male</sex>
         <significant_other_id xsi:nil="true"/>
         <status>
           <message>I rule</message>
           <time>0</time>
         </status>
         <timezone>-8</timezone>
         <tv>cf. Bob Trahan</tv>
         <wall_count>121</wall_count>
         <work_history list="true">
           <work_info>
             <location>
               <city>Palo Alto</city>
               <state>CA</state>
               <country>United States</country>
             </location>
             <company_name>Facebook</company_name>
             <position>Software Engineer</position>
             <description>Tech Lead, Facebook Platform</description>
             <start_date>2006-01</start_date>
             <end_date/>
            </work_info>
         </work_history>
       </user>
       <user>
         <uid>1240079</uid>
         <about_me>I am here.</about_me>
         <activities>Party.</activities>       
       </user>
    </users_getInfo_response>    
    XML
  end
  
  def example_friends_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <uid>222333</uid>
      <uid>1240079</uid>
    </friends_get_response>
    XML
  end
  
  def example_get_logged_in_user_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <users_getLoggedInUser_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">1240077</users_getLoggedInUser_response>    
    XML
  end
  
  def example_auth_token_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <auth_createToken_response xmlns="http://api.facebook.com/1.0/" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
        xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
        3e4a22bb2f5ed75114b0fc9995ea85f1
        </auth_createToken_response>    
    XML
  end
  
  def example_get_session_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <auth_getSession_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <session_key>5f34e11bfb97c762e439e6a5-8055</session_key>
      <uid>8055</uid>
      <expires>1173309298</expires>
      <secret>ohairoflamao12345</secret>
    </auth_getSession_response>    
    XML
  end
  
  def example_invalid_api_key_error_response
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <error_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <error_code>101</error_code>
      <error_msg>Invalid API key</error_msg>
      <request_args list="true">
        <arg>
          <key>v</key>
          <value>1.0</value>
        </arg>
        <arg>
          <key>method</key>
          <value>facebook.auth.createToken</value>
        </arg>
        <arg>
          <key>sig</key>
          <value>611f5f44e55f3fe17f858a8de84a4b0a</value>
        </arg>
        <arg>
          <key>call_id</key>
          <value>1186088346.82142</value>
        </arg>
      </request_args>
    </error_response>    
    XML
  end
  
  def example_session_expired_error_response
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <error_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <error_code>102</error_code>
      <error_msg>Session Expired</error_msg>
      <request_args list="true">
        <arg>
          <key>v</key>
          <value>1.0</value>
        </arg>
        <arg>
          <key>method</key>
          <value>facebook.auth.createToken</value>
        </arg>
        <arg>
          <key>sig</key>
          <value>611f5f44e55f3fe17f858a8de84a4b0a</value>
        </arg>
        <arg>
          <key>call_id</key>
          <value>1186088346.82142</value>
        </arg>
      </request_args>
    </error_response>    
    XML
  end

  def example_app_users_xml
    <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
      <friends_getAppUsers_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
        <uid>222333</uid>
        <uid>1240079</uid>
      </friends_getAppUsers_response> 
    XML
  end
  
  def example_user_albums_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_getAlbums_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <album>
        <aid>97503428432802022</aid>
        <cover_pid>97503428461115574</cover_pid>
        <owner>22701786</owner>
        <name>Summertime is Best</name>
        <created>1184120648</created>
        <modified>1185465771</modified>
        <description>Happenings on or around Summer '07</description>
        <location>Brooklyn, New York</location>
        <link>http://www.facebook.com/album.php?aid=2011366&amp;id=22701786</link>
        <size>49</size>
      </album>
      <album>
        <aid>97503428432797817</aid>
        <cover_pid>97503428460977993</cover_pid>
        <owner>22701786</owner>
        <name>Bonofon's Recital</name>
        <created>1165356279</created>
        <modified>1165382364</modified>
        <description>The whole Ewing fam flies out to flatland to watch the Bonofon's senior recital.  That boy sure can tinkle them ivories.</description>
        <location>Grinnell College, Grinnell Iowa</location>
        <link>http://www.facebook.com/album.php?aid=2007161&amp;id=22701786</link>
        <size>14</size>
      </album>
    </photos_getAlbums_response>
    XML
  end
  
  def example_new_album_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <photos_createAlbum_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <aid>34595963571485</aid>
      <cover_pid>0</cover_pid>
      <owner>8055</owner>
      <name>My Empty Album</name>
      <created>1132553109</created>
      <modified>1132553363</modified>
      <description>No I will not make out with you</description>
      <location>York, PA</location>
      <link>http://www.facebook.com/album.php?aid=2002205&id=8055</link>
      <size>0</size>
    </photos_createAlbum_response>
    XML
  end
  
  
end
