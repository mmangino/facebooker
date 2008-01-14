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
    @session.expects(:post).with('facebook.profile.setFBML', :uid=>1234,:markup=>"profile",:profile_action=>"action",:mobile_fbml=>"mobile")
    @user.set_profile_fbml("profile","mobile","action")
  end
  
  def test_to_s
    assert_equal("1234",@user.to_s)
  end
end