require File.dirname(__FILE__) + '/test_helper.rb'
require 'facebooker'
class SessionTest < Test::Unit::TestCase


  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'   
    Facebooker.current_adapter = nil 
    @bebo_api_key = "bebo_api_key"; @bebo_secret_key = "bebo_secret_key"    
  end

  def teardown
   flexmock_close
  end
  
  def test_load_default_adapter
    session = Facebooker::CanvasSession.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    assert_equal(ENV['FACEBOOK_API_KEY'], Facebooker::Session.api_key)
    assert( Facebooker::FacebookAdapter === Facebooker.current_adapter)
    
    ENV['FACEBOOK_API_KEY'] = nil
    ENV['FACEBOOK_SECRET_KEY'] = nil   
    Facebooker.current_adapter = nil 
    Facebooker::AdapterBase.stubs(:facebooker_config).returns({"api_key" => "facebook_key", "secret_key" => "facebook_secret" })
    assert( Facebooker::FacebookAdapter === Facebooker.current_adapter)
    assert_equal("facebook_key", Facebooker::Session.api_key)
  end
  
  def test_load_bebo_adapter
   
    load_bebo_adapter
    assert_equal(@bebo_api_key, Facebooker::Session.api_key)
    assert_equal(@bebo_secret_key, Facebooker::Session.secret_key)
    assert(Facebooker::BeboAdapter === Facebooker.current_adapter, " Bebo adapter not loaded correctly.")
  end
  
  def load_bebo_adapter
    @bebo_api_key = "bebo_api_key"; @bebo_secret_key = "bebo_secret_key"    

    Facebooker::AdapterBase.stubs(:facebooker_config).returns({"bebo_api_key" => @bebo_api_key, "bebo_adapter" => "BeboAdapter", "bebo_secret_key" => @bebo_secret_key, "foo" => "bar"})
    Facebooker.load_adapter(:config_key_base => "bebo")
    @session = Facebooker::CanvasSession.create(@bebo_api_key, @bebo_secret_key)
  end
  
  def test_adapter_details
     test_load_default_adapter

     assert_equal("apps.facebook.com", Facebooker.canvas_server_base)
     assert_equal("api.facebook.com", Facebooker.api_server_base)
     assert_equal("www.facebook.com", Facebooker.www_server_base_url)
     assert_equal("http://api.facebook.com", Facebooker.api_server_base_url)
     assert(Facebooker.is_for?(:facebook))
    load_bebo_adapter
    
      assert_equal("apps.bebo.com", Facebooker.canvas_server_base)
     assert_equal("apps.bebo.com", Facebooker.api_server_base)
     assert_equal("www.bebo.com", Facebooker.www_server_base_url)
     assert_equal("http://apps.bebo.com", Facebooker.api_server_base_url)
     assert_equal("http://www.bebo.com/SignIn.jsp?ApiKey=bebo_api_key&v=1.0&canvas=true", @session.login_url)
     assert_equal("http://www.bebo.com/c/apps/add?ApiKey=bebo_api_key&v=1.0", @session.install_url)
     assert(Facebooker.is_for?(:bebo))
     
  end
  
  def test_adapter_failures
      Facebooker::AdapterBase.stubs(:facebooker_config).returns({})
      
      assert_raises(Facebooker::AdapterBase::UnableToLoadAdapter){
        Facebooker.load_adapter(:config_key_base => "bebo")
      }
  end
  
  def test_bebo_specific_issues
    load_bebo_adapter
     
    # @session.send(:service).stubs(:post).returns([{:name => "foo"}])
     Net::HTTP.stubs(:post_form).returns("<profile_setFBML_response></profile_setFBML_response>")
     user = Facebooker::User.new(:uid => "123456")
     user.session = @session
     user.set_profile_fbml("foo","bar","foo")
     assert(true)
     Net::HTTP.stubs(:post_form).returns("<users_getInfo_response> <user><uid>123456</uid><name>foo</name></user></users_getInfo_response>")
     user.populate(:name)
     assert(true)
     assert_equal("foo", user.name)
     action = Facebooker::Feed::TemplatizedAction.new()
     action.title_template = "foo"
     Net::HTTP.stubs(:post_form).returns("<feed_publishTemplatizedAction_response>1</feed_publishTemplatizedAction_response>")
     user.publish_templatized_action(action)
  end
  
  def test_bebo_process_data
    
  end
  

end
