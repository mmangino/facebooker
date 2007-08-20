require File.dirname(__FILE__) + '/test_helper.rb'

class SessionTest < Test::Unit::TestCase


  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'   
    @session = Facebooker::Session.create('whatever', 'doesnotmatterintest')     
  end

  def teardown
    flexmock_close
  end
  def test_can_get_api_and_secret_key_from_environment
    assert_equal('1234567', Facebooker::Session.api_key)
    assert_equal('7654321', Facebooker::Session.secret_key)    
  end
  
  def test_if_keys_are_not_available_via_environment_then_they_are_gotten_from_a_file
    ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'] = nil
    flexmock(File).should_receive(:read).with(File.expand_path("~/.facebookerrc")).once.and_return('{:api => "foo"}')
    assert_equal('foo', Facebooker::Session.api_key)
  end
  
  def test_if_environment_and_file_fail_to_match_then_an_exception_is_raised
    ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'] = nil
    flexmock(File).should_receive(:read).with(File.expand_path("~/.facebookerrc")).once.and_return {raise Errno::ENOENT, "No such file"}
    assert_raises(Facebooker::Session::ConfigurationMissing) {
      Facebooker::Session.api_key
    }
  end
  
  def test_configuration_file_path_can_be_set_explicitly
    Facebooker::Session.configuration_file_path = '/tmp/foo'
    assert_equal('/tmp/foo', Facebooker::Session.configuration_file_path)
  end
  
  def test_session_can_be_secured_with_existing_values
    session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    session.secure_with!("a session key", "123456", Time.now.to_i + 60)
    assert(session.secured?)
  end
  
  # The Facebook API for this is hideous.  Oh well.
  def test_can_ask_session_to_check_friendship_between_pairs_of_users
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_check_friendship_xml).once.ordered(:posts)
    assert_equal({[222332, 222333] => true, [1240077, 1240079] => false}, @session.check_friendship([[222332, 222333], [1240077, 1240079]]))    
  end
  
  def test_facebook_can_claim_ignorance_as_to_friend_relationships
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_check_friendship_with_unknown_result).once.ordered(:posts)  
    assert_equal({[1240077, 1240079] => nil}, @session.check_friendship([[1240077, 1240079]]))  
  end
  
  def test_can_query_with_fql
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_fql_for_multiple_photos_xml)    
    response = @session.fql_query('SELECT src, caption, 1+2*3/4, caption, 10*(20 + 1) FROM photo
    WHERE pid IN (SELECT pid FROM photo_tag WHERE subject= 22701786) AND
          pid IN (SELECT pid FROM photo_tag WHERE subject= 22701786) AND
          caption')
    assert_kind_of(Facebooker::Photo, response.first)      
  end
  
  def test_fql_can_return_anonymous_field_values
    fail("Man I hate the facebook API")
  end
  
  def test_can_fql_query_for_event_members
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    expect_http_posts_with_responses(example_fql_query_event_members_xml)
    response = @session.fql_query("DOES NOT REALLY MATTER FOR TEST")
    assert_kind_of(Facebooker::Event, response.first)
  end
  
  
  def test_can_query_for_events
    expect_http_posts_with_responses(example_events_get_xml)    
    events = @session.events
    assert_equal 'Technology Tasting', events.first.name
  end
  
  def test_can_fql_query_for_users_and_pictures
    @session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    mock_http = establish_session
    mock_http.should_receive(:post_form).and_return(example_fql_for_multiple_users_and_pics).once.ordered(:posts)  
    response = @session.fql_query('SELECT name, pic FROM user WHERE uid=211031 OR uid=4801660')
    assert_kind_of Array, response
    assert_kind_of Facebooker::User, response.first
    assert_equal "Ari Steinberg", response.first.name
  end
  
  def teardown
    Facebooker::Session.configuration_file_path = nil
  end
  
  private
  
  def example_events_get_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <events_get_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <event>
        <eid>1037629024</eid>
        <name>Technology Tasting</name>
        <tagline>Who said Engineering can't be delicious?</tagline>
        <nid>12409987</nid>
        <pic>http://photos-628.facebook.com/ip006/object/1345/48/s1037629024_30775.jpg</pic>
        <pic_big>http://photos-628.facebook.com/ip006/object/1345/48/n1037629024_30775.jpg</pic_big>
        <pic_small>http://photos-628.facebook.com/ip006/object/1345/48/t1037629024_30775.jpg</pic_small>
        <host>Facebook</host>
        <description>Facebook will be hosting technology thought leaders and avid software engineers for a social evening of technology tasting. We invite you to connect with some of our newest technologies and innovative people over hors d'oeuvres and wine. Come share ideas, ask questions, and challenge existing technology paradigms in the spirit of the open source community.</description>
        <event_type>Party</event_type>
        <event_subtype>Cocktail Party</event_subtype>
        <start_time>1172107800</start_time>
        <end_time>1172115000</end_time>
        <creator>1078</creator>
        <update_time>1170096157</update_time>
        <location>Facebook's New Office</location>
        <venue>
          <city>Palo Alto</city>
          <state>CA</state>
          <country>United States</country>
        </venue>
      </event>
    </events_get_response>    
    XML
  end
  
  def example_fql_query_event_members_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <event_member>
        <eid>2454827764</eid>
      </event_member>
      <event_member>
        <eid>2454827764</eid>
      </event_member>
    </fql_query_response>    
    XML
  end
  def example_check_friendship_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_areFriends_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <friend_info>
        <uid1>222332</uid1>
        <uid2>222333</uid2>
        <are_friends>1</are_friends>
      </friend_info>
      <friend_info>
        <uid1>1240077</uid1>
        <uid2>1240079</uid2>
        <are_friends>0</are_friends>
      </friend_info>
    </friends_areFriends_response>    
    XML
  end
  
  def example_check_friendship_with_unknown_result
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <friends_areFriends_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" list="true">
      <friend_info>
        <uid1>1240077</uid1>
        <uid2>1240079</uid2>
        <are_friends xsi:nil="true"/>
      </friend_info>
    </friends_areFriends_response>    
    XML
  end
  
  def example_fql_for_multiple_users_and_pics
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <user>
        <name>Ari Steinberg</name>
        <pic>http://profile.ak.facebook.com/profile2/1805/47/s211031_26434.jpg</pic>
      </user>
      <user>
        <name>Ruchi Sanghvi</name>
        <pic>http://profile.ak.facebook.com/v52/870/125/s4801660_2498.jpg</pic>
      </user>
    </fql_query_response>
    XML
  end
  
  def example_fql_for_multiple_photos_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <fql_query_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" list="true">
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v108/212/118/22700225/s22700225_30345986_2713.jpg</src>
        <caption>Nottttt. get ready for some museumz</caption>
        <caption>Nottttt. get ready for some museumz</caption>
      </photo>
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sf2p/v77/74/112/22701786/s22701786_30324934_7816.jpg</src>
        <caption>Rooftop barbecues make me act funny</caption>
        <caption>Rooftop barbecues make me act funny</caption>
      </photo>
      <photo>
        <src>http://photos-c.ak.facebook.com/photos-ak-sctm/v96/154/56/22700188/s22700188_30321538_17.jpg</src>
        <caption>An epic shot of Patrick getting ready for a run to second.</caption>
        <caption>An epic shot of Patrick getting ready for a run to second.</caption>
      </photo>
    </fql_query_response>
    XML
  end
  
  
end
