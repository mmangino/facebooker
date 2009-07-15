require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'active_support'

class Facebooker::PageTest < Test::Unit::TestCase

  def test_should_be_able_to_populate_with_photo_id_as_integer
    p = Facebooker::Page.new(12345)
    assert_equal(12345,p.page_id)
  end
  
  def test_should_be_ble_to_initialize_with_photo_id_as_string
    p = Facebooker::Page.new("12345")
    assert_equal("12345",p.page_id)    
  end
  
  def test_should_be_able_to_initialize_with_hash
    p = Facebooker::Page.new(:page_id=>12345,:name=>"test page")
    assert_equal("test page",p.name)
    assert_equal(12345,p.page_id)
  end
  
  def test_should_be_able_to_see_if_user_is_fan_with_id
    Facebooker::Session.current.expects(:post).with("facebook.pages.isFan",:page_id=>12345,:uid=>12451752).returns(true)
    p = Facebooker::Page.new(12345)
    assert p.user_is_fan?(12451752)
  end
  
  def test_should_be_able_to_see_if_user_is_fan_with_user
    Facebooker::Session.current.expects(:post).with("facebook.pages.isFan",:page_id=>12345,:uid=>12451752).returns(false)
    p = Facebooker::Page.new(12345)
    assert !p.user_is_fan?(Facebooker::User.new(12451752))
  end
  
  def test_should_be_able_to_see_if_user_is_admin_with_id
    Facebooker::Session.current.expects(:post).with("facebook.pages.isAdmin",:page_id=>12345,:uid=>12451752).returns(false)
    p = Facebooker::Page.new(12345)
    assert !p.user_is_admin?(12451752)
    
  end
  
  def test_should_be_able_to_see_if_user_is_admin_with_user
    Facebooker::Session.current.expects(:post).with("facebook.pages.isAdmin",:page_id=>12345,:uid=>12451752).returns(true)
    p = Facebooker::Page.new(12345)
    assert p.user_is_admin?(Facebooker::User.new(12451752))
  end
end