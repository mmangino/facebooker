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
  
end
