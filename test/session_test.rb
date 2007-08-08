require File.dirname(__FILE__) + '/test_helper.rb'

class SessionTest < Test::Unit::TestCase


  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'    
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
  
  def teardown
    Facebooker::Session.configuration_file_path = nil
  end
  
  private
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
  
end
