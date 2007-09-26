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
end