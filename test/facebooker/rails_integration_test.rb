require File.expand_path(File.dirname(__FILE__) + '/../rails_test_helper')

module FBConnectTestHelpers
  def setup_fb_connect_cookies(params=cookie_hash_for_auth)
    params.each {|k,v| @request.cookies[ENV['FACEBOOK_API_KEY']+k] = CGI::Cookie.new(ENV['FACEBOOK_API_KEY']+k,v)}
  end

  def expired_cookie_hash_for_auth
    {"_ss" => "not_used", "_session_key"=> "whatever", "_user"=>"77777", "_expires"=>"#{1.day.ago.to_i}"}
  end

  def cookie_hash_for_auth
    {"_ss" => "not_used", "_session_key"=> "whatever", "_user"=>"77777", "_expires"=>"#{1.day.from_now.to_i}"}
  end
end
class NoisyController < ActionController::Base
  include Facebooker::Rails::Controller
  def rescue_action(e) raise e end
end


class ControllerWhichRequiresExtendedPermissions< NoisyController
  ensure_authenticated_to_facebook
  before_filter :ensure_has_status_update
  before_filter :ensure_has_photo_upload
  before_filter :ensure_has_video_upload
  before_filter :ensure_has_create_listing
  def index
    render :text => 'score!'
  end
end

class FBConnectController < NoisyController
  before_filter :create_facebook_session
  def index
    render :text => 'score!'
  end
end

class FBConnectControllerProxy < NoisyController
  before_filter :create_facebook_session_with_secret
  def index
    render :text => 'score!'
  end
end

class ControllerWhichRequiresFacebookAuthentication < NoisyController
  ensure_authenticated_to_facebook
  def index
    render :text => 'score!'
  end
  def link_test
    options = {}
    options[:canvas] = true if params[:canvas] == true
    options[:canvas] = false if params[:canvas] == false
    render :text=>url_for(options)
  end
  
   def named_route_test
    render :text=>comments_url()
  end
  
  def image_test
    render :inline=>"<%=image_tag 'image.png'%>"
  end
  
  def fb_params_test
    render :text=>facebook_params['user']
  end
  
  def publisher_test
    if wants_interface?
      render :text=>"interface"
    else
      render :text=>"not interface"
    end
  end
  
  def publisher_test_interface
    render_publisher_interface("This is a test",false,true)
  end
  
  def publisher_test_response
    ua=Facebooker::Rails::Publisher::UserAction.new
    ua.data = {:params=>true}
    ua.template_name = "template_name"
    ua.template_id =  1234
    render_publisher_response(ua)
  end
  
  def publisher_test_error
    render_publisher_error("Title","Body")
  end
  
end
class ControllerWhichRequiresApplicationInstallation < NoisyController
  ensure_application_is_installed_by_facebook_user
  def index
    render :text => 'installed!'
  end    
end
class FacebookController < ActionController::Base
  def index
  end
end

class PlainOldRailsController < ActionController::Base
  def index
  end
  def link_test
    options = {}
    options[:canvas] = true if params[:canvas] == true
    options[:canvas] = false if params[:canvas] == false
    render :text => url_for(options)
  end
  
  def named_route_test
    render :text=>comments_url()
  end
  def canvas_false_test
    render :text=>comments_url(:canvas=>false)
  end
  def canvas_true_test
    render :text=>comments_url(:canvas=>true)
  end
end


# you can't use asset_recognize, because it can't pass parameters in to the requests
class UrlRecognitionTests < Test::Unit::TestCase
  def test_detects_in_canvas
    if Rails.version < '2.3'
      request = ActionController::TestRequest.new({"fb_sig_in_canvas"=>"1"}, {}, nil)
    else
      request = ActionController::TestRequest.new
      request.query_parameters[:fb_sig_in_canvas] = "1"
    end
    request.path   = "/"
    ActionController::Routing::Routes.recognize(request)
    assert_equal({"controller"=>"facebook","action"=>"index"},request.path_parameters)
  end
  
  def test_routes_when_not_in_canvas
    if Rails.version < '2.3'
      request = ActionController::TestRequest.new({}, {}, nil)
    else
      request = ActionController::TestRequest.new
    end
    request.path   = "/"
    ActionController::Routing::Routes.recognize(request)
    assert_equal({"controller"=>"plain_old_rails","action"=>"index"},request.path_parameters)
  end
end

class RailsIntegrationTestForFBConnect < Test::Unit::TestCase
  include FBConnectTestHelpers
  
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'canvas_page_name' => 'facebook_app_name',
      'secret_key'       => '7654321' })
    @controller = FBConnectController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:verify_signature).returns(true)
            
  end
  
  def test_doesnt_set_cookie_but_facebook_session_is_available
    setup_fb_connect_cookies
    get :index
    assert_not_nil @controller.facebook_session
    assert_nil @response.cookies[:facebook_session] 
    
  end
end

class RailsIntegrationTestForNonFacebookControllers < Test::Unit::TestCase
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'canvas_page_name' => 'facebook_app_name',
      'secret_key'       => '7654321' })
    @controller = PlainOldRailsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new        
  end

  def test_url_for_links_to_callback_if_canvas_is_false_and_in_canvas
    get :link_test
    assert_match(/test.host/, @response.body)
  end
  
  def test_named_route_doesnt_include_canvas_path_when_not_in_canvas
    get :named_route_test
    assert_equal "http://test.host/comments",@response.body
  end
  def test_named_route_includes_canvas_path_when_in_canvas
    get :named_route_test, facebook_params
    assert_equal "http://apps.facebook.com/facebook_app_name/comments",@response.body
  end
 
  def test_named_route_doesnt_include_canvas_path_when_in_canvas_with_canvas_equals_false
    get :canvas_false_test, facebook_params
    assert_equal "http://test.host/comments",@response.body
  end
  def test_named_route_does_include_canvas_path_when_not_in_canvas_with_canvas_equals_true
    get :canvas_true_test
    assert_equal "http://apps.facebook.com/facebook_app_name/comments",@response.body
  end
  
end
  
class RailsIntegrationTestForExtendedPermissions < Test::Unit::TestCase
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'secret_key'       => '7654321' })
    @controller = ControllerWhichRequiresExtendedPermissions.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:verify_signature).returns(true)
  end
  
  def test_redirects_without_set_status
    post :index, facebook_params
    assert_response :success
    assert_equal("<fb:redirect url=\"http://www.facebook.com/authorize.php?api_key=1234567&v=1.0&ext_perm=status_update\" />", @response.body)
  end
  def test_redirects_without_photo_upload
    post :index, facebook_params(:fb_sig_ext_perms=>"status_update")
    assert_response :success
    assert_equal("<fb:redirect url=\"http://www.facebook.com/authorize.php?api_key=1234567&v=1.0&ext_perm=photo_upload\" />", @response.body)
  end
  def test_redirects_without_video_upload
    post :index, facebook_params(:fb_sig_ext_perms=>"status_update,photo_upload")
    assert_response :success
    assert_equal("<fb:redirect url=\"http://www.facebook.com/authorize.php?api_key=1234567&v=1.0&ext_perm=video_upload\" />", @response.body)
  end
  def test_redirects_without_create_listing
    post :index, facebook_params(:fb_sig_ext_perms=>"status_update,photo_upload,video_upload")
    assert_response :success
    assert_equal("<fb:redirect url=\"http://www.facebook.com/authorize.php?api_key=1234567&v=1.0&ext_perm=create_listing\" />", @response.body)
  end
  
  def test_renders_with_permission
    post :index, facebook_params(:fb_sig_ext_perms=>"status_update,photo_upload,create_listing,video_upload")
    assert_response :success
    assert_equal("score!", @response.body)
    
  end
end  
  
class RailsIntegrationTestForApplicationInstallation < Test::Unit::TestCase
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'secret_key'       => '7654321' })
    @controller = ControllerWhichRequiresApplicationInstallation.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:verify_signature).returns(true)
  end
  
  def test_if_controller_requires_application_installation_unauthenticated_requests_will_redirect_to_install_page
    get :index
    assert_response :redirect
    assert_equal("http://www.facebook.com/install.php?api_key=1234567&v=1.0&next=http%3A%2F%2Ftest.host%2Frequire_install", @response.headers['Location'])
  end
  
  def test_if_controller_requires_application_installation_authenticated_requests_without_installation_will_redirect_to_install_page
    get :index, facebook_params(:fb_sig_added => nil)
    assert_response :success
    assert(@response.body =~ /fb:redirect/)
  end
  
  def test_if_controller_requires_application_installation_authenticated_requests_with_installation_will_render
    get :index, facebook_params('fb_sig_added' => "1")
    assert_response :success
    assert_equal("installed!", @response.body)
  end
end
  
class RailsIntegrationTest < Test::Unit::TestCase
  include FBConnectTestHelpers
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'canvas_page_name' => 'root',
      'secret_key'       => '7654321',
      'set_asset_host_to_callback_url' => true,
      'callback_url'     => "http://root.example.com" })
    @controller = ControllerWhichRequiresFacebookAuthentication.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
    @controller.stubs(:verify_signature).returns(true)
    
  end
  
  def test_named_route_includes_new_canvas_path_when_in_new_canvas
    get :named_route_test, facebook_params("fb_sig_in_new_facebook"=>"1")
    assert_equal "http://apps.facebook.com/root/comments",@response.body
  end

  def test_if_controller_requires_facebook_authentication_unauthenticated_requests_will_redirect
    get :index
    assert_response :redirect
    assert_equal("http://www.facebook.com/login.php?api_key=1234567&v=1.0&next=http%3A%2F%2Ftest.host%2Frequire_auth", @response.headers['Location'])
  end

  def test_facebook_params_are_parsed_into_a_separate_hash
    get :index, facebook_params(:fb_sig_user => '9')
    assert_not_nil @controller.facebook_params['time']
  end
  
  def test_facebook_params_convert_in_canvas_to_boolean
    get :index, facebook_params
    assert_equal(true, @controller.facebook_params['in_canvas'])    
  end
  
  def test_facebook_params_convert_added_to_boolean_false
    get :index, facebook_params(:fb_sig_added => '0')
    assert_equal(false, @controller.facebook_params['added'])
  end
  
  def test_facebook_params_convert_added_to_boolean_true
    get :index, facebook_params('fb_sig_added' => "1")
    assert_equal(true, @controller.facebook_params['added'])
  end

  def test_facebook_params_convert_added_to_boolean_false_when_already_false
    get :index, facebook_params('fb_sig_added' => false)
    assert_equal(false, @controller.facebook_params['added'])
  end

  def test_facebook_params_convert_added_to_boolean_true_when_already_true
    get :index, facebook_params('fb_sig_added' => true)
    assert_equal(true, @controller.facebook_params['added'])
  end
  
  def test_facebook_params_convert_expirey_into_nil
    get :index, facebook_params(:fb_sig_expires => '0')
    assert_nil(@controller.facebook_params['expires'])
  end
  
  def test_facebook_params_convert_expirey_into_time
    get :index, facebook_params(:fb_sig_expires => 5.minutes.from_now.to_f)
    assert_instance_of Time, @controller.facebook_params['expires']
  end
  
  def test_facebook_params_convert_friend_list_to_parsed_array_of_friend_ids
    get :index, facebook_params(:fb_sig_friends => '1,2,3,4,5')
    assert_kind_of(Array, @controller.facebook_params['friends'])    
    assert_equal(5, @controller.facebook_params['friends'].size)
  end
  
  def test_session_can_be_resecured_from_facebook_params
    get :index, facebook_params(:fb_sig_user => 10)
    assert_equal(10, @controller.facebook_session.user.id)    
  end
  
  def test_existing_secured_session_is_used_if_available
    session = Facebooker::Session.create(Facebooker::Session.api_key, Facebooker::Session.secret_key)
    session.secure_with!("session_key", "111", Time.now.to_i + 60)
    get :index, facebook_params(:fb_sig_session_key => 'session_key', :fb_sig_user => '987'), {:facebook_session => session}
    assert_equal(111, @controller.facebook_session.user.id)
  end

  def test_facebook_params_used_if_existing_secured_session_key_does_not_match
    session = Facebooker::Session.create(Facebooker::Session.api_key, Facebooker::Session.secret_key)
    session.secure_with!("different session key", "111", Time.now.to_i + 60)
    get :index, facebook_params(:fb_sig_session_key => '', :fb_sig_user => '123'), {:facebook_session => session}
    assert_equal(123, @controller.facebook_session.user.id)
  end

  def test_existing_secured_session_is_NOT_used_if_available_and_facebook_params_session_key_is_nil_and_in_canvas
    session = Facebooker::Session.create(Facebooker::Session.api_key, Facebooker::Session.secret_key)
    session.secure_with!("session_key", "111", Time.now.to_i + 60)
    session.secure_with!("a session key", "1111111", Time.now.to_i + 60)
    get :index, facebook_params(:fb_sig_session_key => '', :fb_sig_user => '987'), {:facebook_session => session}
    assert_equal(987, @controller.facebook_session.user.id)
  end

  def test_existing_secured_session_IS_used_if_available_and_facebook_params_session_key_is_nil_and_NOT_in_canvas
    @contoller = PlainOldRailsController.new
    session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    session.secure_with!("a session key", "1111111", Time.now.to_i + 60)
    get :index,{}, {:facebook_session => session}
    
    assert_equal(1111111, @controller.facebook_session.user.id)
  end

  def test_session_can_be_secured_with_secret
    @controller = FBConnectControllerProxy.new
    auth_token = 'ohaiauthtokenhere111'
    modified_params = facebook_params
    modified_params.delete('fb_sig_session_key')
    modified_params['auth_token'] = auth_token
    modified_params['generate_session_secret'] = true
    session_mock = flexmock(session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY']))
    session_params = { 'session_key' => '123', 'uid' => '321' }
    session_mock.should_receive(:post).with('facebook.auth.getSession', :auth_token => auth_token, :generate_session_secret => "1").once.and_return(session_params).ordered
    flexmock(@controller).should_receive(:new_facebook_session).once.and_return(session).ordered
    get :index, modified_params
  end

  def test_session_can_be_secured_with_auth_token
    auth_token = 'ohaiauthtokenhere111'
    modified_params = facebook_params
    modified_params.delete('fb_sig_session_key')
    modified_params['auth_token'] = auth_token
    session_mock = flexmock(session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY']))
    session_params = { 'session_key' => '123', 'uid' => '321' }
    session_mock.should_receive(:post).with('facebook.auth.getSession', :auth_token => auth_token, :generate_session_secret => "0").once.and_return(session_params).ordered
    flexmock(@controller).should_receive(:new_facebook_session).once.and_return(session).ordered
    get :index, modified_params
  end
  
  def test_session_secured_with_auth_token_if_cookies_expired
      auth_token = 'ohaiauthtokenhere111'
      modified_params = facebook_params
      modified_params.delete('fb_sig_session_key')
      modified_params['auth_token'] = auth_token
      session_mock = flexmock(session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY']))
      session_params = { 'session_key' => '123', 'uid' => '321' }
      session_mock.should_receive(:post).with('facebook.auth.getSession', :auth_token => auth_token, :generate_session_secret => "0").once.and_return(session_params).ordered
      flexmock(@controller).should_receive(:new_facebook_session).once.and_return(session).ordered
      setup_fb_connect_cookies(expired_cookie_hash_for_auth)
      get :index, modified_params
      assert_equal(321, @controller.facebook_session.user.id)
  end
          
  def test_session_can_be_secured_with_cookies
    setup_fb_connect_cookies
    get :index
    assert_equal(77777, @controller.facebook_session.user.id)
  end
  
  def test_session_does_NOT_secure_with_expired_cookies
    setup_fb_connect_cookies(expired_cookie_hash_for_auth)
    get :index
    assert_nil(@controller.facebook_session)
  end
      
  def test_user_friends_can_be_populated_from_facebook_params_if_available
    get :index, facebook_params(:fb_sig_friends => '1,2,3,4')
    friends = @controller.facebook_session.user.friends
    assert_not_nil(friends)
    assert_equal(4, friends.size)    
  end
  
  def test_fbml_redirect_tag_handles_hash_parameters_correctly
    get :index, facebook_params
    assert_equal "<fb:redirect url=\"http://apps.facebook.com/root/require_auth\" />", @controller.send(:fbml_redirect_tag, :action => :index,:canvas=>true)
  end
  
  def test_redirect_to_renders_fbml_redirect_tag_if_request_is_for_a_facebook_canvas
    get :index, facebook_params(:fb_sig_user => nil)
    assert_response :success
    assert @response.body =~ /fb:redirect/
  end
  
  def test_redirect_to_renders_javascript_redirect_if_request_is_for_a_facebook_iframe
    get :index, facebook_params(:fb_sig_user => nil, :fb_sig_in_iframe => 1)
    assert_response :success
    assert_match "javascript", @response.body
    assert_match "http-equiv", @response.body
    assert_match "http://www.facebook.com/login.php?api_key=1234567&amp;v=1.0", @response.body
  end

  def test_url_for_links_to_canvas_if_canvas_is_true_and_not_in_canvas
    get :link_test, facebook_params(:fb_sig_in_canvas=>0,:canvas=>true)
    assert_match(/apps.facebook.com/, @response.body)
  end

  def test_includes_relative_url_root_when_linked_to_canvas
    get :link_test,facebook_params(:fb_sig_in_canvas=>0,:canvas=>true)
    assert_match(/root/,@response.body)
  end

  def test_url_for_links_to_callback_if_canvas_is_false_and_in_canvas
    get :link_test,facebook_params(:fb_sig_in_canvas=>0,:canvas=>false)
    assert_match(/test.host/,@response.body)
  end

  def test_url_for_doesnt_include_url_root_when_not_linked_to_canvas
    get :link_test,facebook_params(:fb_sig_in_canvas=>0,:canvas=>false)
    assert !@response.body.match(/root/)
  end
  
  def test_default_url_omits_fb_params
    get :index,facebook_params(:fb_sig_friends=>"overwriteme",:get_param=>"yes")
    assert_equal "http://apps.facebook.com/root/require_auth?get_param=yes", @controller.send(:default_after_facebook_login_url)
  end

  def test_url_for_links_to_canvas_if_canvas_is_not_set
    get :link_test,facebook_params
    assert_match(/apps.facebook.com/,@response.body)
  end

  def test_image_tag
    get :image_test, facebook_params
    assert_equal "<img alt=\"Image\" src=\"http://root.example.com/images/image.png\" />",@response.body
  end
  
  def test_wants_interface_is_available_and_detects_method
    get :publisher_test, facebook_params(:method=>"publisher_getInterface")
    assert_equal "interface",@response.body
  end
  def test_wants_interface_is_available_and_detects_not_interface
    get :publisher_test, facebook_params(:method=>"publisher_getFeedStory")
    assert_equal "not interface",@response.body
  end
  
  def test_publisher_test_error
    get :publisher_test_error, facebook_params
    assert_equal Facebooker.json_decode("{\"errorCode\": 1, \"errorTitle\": \"Title\", \"errorMessage\": \"Body\"}"), Facebooker.json_decode(@response.body)
  end
  
  def test_publisher_test_interface
    get :publisher_test_interface, facebook_params
    assert_equal Facebooker.json_decode("{\"method\": \"publisher_getInterface\", \"content\": {\"fbml\": \"This is a test\", \"publishEnabled\": false, \"commentEnabled\": true}}"), Facebooker.json_decode(@response.body)
  end
  
  def test_publisher_test_reponse
    get :publisher_test_response, facebook_params
    assert_equal Facebooker.json_decode("{\"method\": \"publisher_getFeedStory\", \"content\": {\"feed\": {\"template_data\": {\"params\": true}, \"template_id\": 1234}}}"), Facebooker.json_decode(@response.body)
    
  end
  
  private

  def expired_cookie_hash_for_auth
    {"_ss" => "not_used", "_session_key"=> "whatever", "_user"=>"77777", "_expires"=>"#{1.day.ago.to_i}"}
  end

  def cookie_hash_for_auth
    {"_ss" => "not_used", "_session_key"=> "whatever", "_user"=>"77777", "_expires"=>"#{1.day.from_now.to_i}"}
  end
   
end


class RailsSignatureTest < Test::Unit::TestCase
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'canvas_page_name' => 'root',
      'secret_key'       => '7654321' })
    @controller = ControllerWhichRequiresFacebookAuthentication.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    

  end

  if Rails.version < '2.3'
  
    def test_should_raise_on_bad_sig
      begin
        get :fb_params_test, facebook_params.merge('fb_sig' => 'incorrect')
        fail "No IncorrectSignature raised"
      rescue Facebooker::Session::IncorrectSignature=>e
      end
    end

    def test_valid_signature
      @controller.expects(:earliest_valid_session).returns(Time.at(1186588275.5988)-1)
      get :fb_params_test, facebook_params 
    end

  end
  
  def test_should_raise_too_old_for_replayed_session
    begin
      get :fb_params_test, facebook_params('fb_sig_time' => Time.now.to_i - 49.hours)
      fail "No SignatureTooOld raised"
    rescue Facebooker::Session::SignatureTooOld=>e
    end
  end
  
end
class RailsHelperTest < Test::Unit::TestCase
  class HelperClass
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::CaptureHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::JavaScriptHelper
    include Facebooker::Rails::Helpers
    attr_accessor :flash, :output_buffer
    def initialize
      @flash={}
      @template = self
      @content_for_test_param="Test Param"
      @output_buffer = ""
    end
    #used for stubbing out the form builder
    def url_for(arg)
      arg
    end
    def request
      ActionController::TestRequest.new
    end
    def fields_for(*args)
      ""
    end
        
  end 

  # used for capturing the contents of some of the helper tests
  # this duplicates the rails template system  
  attr_accessor :_erbout
  
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'canvas_page_name' => 'facebook',
      'secret_key'       => '7654321' })
    @_erbout = ""
    @h = HelperClass.new
    #use an asset path where the canvas path equals the hostname to make sure we handle that case right
    ActionController::Base.asset_host='http://facebook.host.com'
  end
  
  def test_fb_profile_pic
    assert_equal "<fb:profile-pic uid=\"1234\"></fb:profile-pic>", @h.fb_profile_pic("1234")
  end

  def test_fb_profile_pic_with_valid_size
    assert_equal "<fb:profile-pic size=\"small\" uid=\"1234\"></fb:profile-pic>", @h.fb_profile_pic("1234", :size => :small)
  end

  def test_fb_profile_pic_with_width_and_height
    assert_equal "<fb:profile-pic height=\"200\" uid=\"1234\" width=\"100\"></fb:profile-pic>", @h.fb_profile_pic("1234", :width => 100, :height => 200)
  end

  def test_fb_profile_pic_with_invalid_size
    assert_raises(ArgumentError) {@h.fb_profile_pic("1234", :size => :mediumm)}
  end

  def test_fb_photo
    assert_equal "<fb:photo pid=\"1234\"></fb:photo>",@h.fb_photo("1234")
  end

  def test_fb_photo_with_object_responding_to_photo_id
    photo = flexmock("photo", :photo_id => "5678")
    assert_equal "<fb:photo pid=\"5678\"></fb:photo>", @h.fb_photo(photo)
  end

  def test_fb_photo_with_invalid_size
    assert_raises(ArgumentError) {@h.fb_photo("1234", :size => :medium)}
  end
  
  def test_fb_photo_with_invalid_size_value
    assert_raises(ArgumentError) {@h.fb_photo("1234", :size => :mediumm)}
  end
  
  def test_fb_photo_with_invalid_align_value
    assert_raises(ArgumentError) {@h.fb_photo("1234", :align => :rightt)}
  end

  def test_fb_photo_with_valid_align_value
    assert_equal "<fb:photo align=\"right\" pid=\"1234\"></fb:photo>",@h.fb_photo("1234", :align => :right)
  end

  def test_fb_photo_with_class
    assert_equal "<fb:photo class=\"picky\" pid=\"1234\"></fb:photo>",@h.fb_photo("1234", :class => :picky)
  end
  def test_fb_photo_with_style
    assert_equal "<fb:photo pid=\"1234\" style=\"some=css;put=here;\"></fb:photo>",@h.fb_photo("1234", :style => "some=css;put=here;")
  end
  
  def test_fb_prompt_permission_valid_no_callback
    assert_equal "<fb:prompt-permission perms=\"email\">Can I email you?</fb:prompt-permission>",@h.fb_prompt_permission("email","Can I email you?")    
  end
  
  def test_fb_prompt_permission_valid_with_callback
    assert_equal "<fb:prompt-permission next_fbjs=\"do_stuff()\" perms=\"email\">a message</fb:prompt-permission>",@h.fb_prompt_permission("email","a message","do_stuff()")
  end
  
  def test_fb_prompt_permission_invalid_option
    assert_raises(ArgumentError) {@h.fb_prompt_permission("invliad", "a message")}
    
  end
  
  def test_fb_prompt_permissions_valid_no_callback
    assert_equal "<fb:prompt-permission perms=\"publish_stream,read_stream\">Can I read and write your streams?</fb:prompt-permission>",
                 @h.fb_prompt_permissions(['publish_stream', 'read_stream'],"Can I read and write your streams?")    
  end
  
  def test_fb_prompt_permissions_valid_with_callback
    assert_equal "<fb:prompt-permission next_fbjs=\"do_stuff()\" perms=\"publish_stream,read_stream\">Can I read and write your streams?</fb:prompt-permission>",
                 @h.fb_prompt_permissions(['publish_stream', 'read_stream'],"Can I read and write your streams?", "do_stuff()")    
  end
  
  def test_fb_prompt_permissions_invalid_option
    assert_raises(ArgumentError) {@h.fb_prompt_permissions(["invliad", "read_stream"], "a message")}
    
  end  
 
  
  def test_fb_add_profile_section
    assert_equal "<fb:add-section-button section=\"profile\" />",@h.fb_add_profile_section
  end

  def test_fb_add_info_section
    assert_equal "<fb:add-section-button section=\"info\" />",@h.fb_add_info_section
  end

  def test_fb_application_name
    assert_equal "<fb:application-name />", @h.fb_application_name
  end

  def test_fb_application_name_with_linked_false
    assert_equal '<fb:application-name linked="false" />', @h.fb_application_name( :linked => false )
  end

  def test_fb_name_with_invalid_key_size
    assert_raises(ArgumentError) {@h.fb_name(1234, :sizee => false)}
  end

  def test_fb_name
    assert_equal "<fb:name uid=\"1234\"></fb:name>",@h.fb_name("1234")
  end

  def test_fb_name_with_transformed_key
    assert_equal "<fb:name uid=\"1234\" useyou=\"true\"></fb:name>", @h.fb_name(1234, :use_you => true)
  end

  def test_fb_name_with_user_responding_to_facebook_id
    user = flexmock("user", :facebook_id => "5678")
    assert_equal "<fb:name uid=\"5678\"></fb:name>", @h.fb_name(user)
  end

  def test_fb_name_with_invalid_key_linkd
    assert_raises(ArgumentError) {@h.fb_name(1234, :linkd => false)}
  end

  def test_fb_tabs
    assert_equal "<fb:tabs></fb:tabs>", @h.fb_tabs{}
  end

  def test_fb_tab_item
    assert_equal "<fb:tab-item href=\"http://www.google.com\" title=\"Google\" />", @h.fb_tab_item("Google", "http://www.google.com")
  end

  def test_fb_tab_item_raises_exception_for_invalid_option
    assert_raises(ArgumentError) {@h.fb_tab_item("Google", "http://www.google.com", :alignn => :right)}
  end

  def test_fb_tab_item_raises_exception_for_invalid_align_value
    assert_raises(ArgumentError) {@h.fb_tab_item("Google", "http://www.google.com", :align => :rightt)}
  end
    
  def test_fb_req_choice
    assert_equal "<fb:req-choice label=\"label\" url=\"url\" />", @h.fb_req_choice("label","url")
  end
  
  def test_fb_multi_friend_selector
    assert_equal "<fb:multi-friend-selector actiontext=\"This is a message\" max=\"20\" showborder=\"false\" />", @h.fb_multi_friend_selector("This is a message")
  end
  def test_fb_multi_friend_selector_with_options
    assert_equal "<fb:multi-friend-selector actiontext=\"This is a message\" exclude_ids=\"1,2\" max=\"20\" showborder=\"false\" />", @h.fb_multi_friend_selector("This is a message",:exclude_ids=>"1,2")
  end

  def test_fb_title
    assert_equal "<fb:title>This is the canvas page window title</fb:title>", @h.fb_title("This is the canvas page window title")
  end
  
  def test_fb_google_analytics
    assert_equal "<fb:google-analytics uacct=\"UA-9999999-99\" />", @h.fb_google_analytics("UA-9999999-99")
  end

  def test_fb_if_is_user_with_single_object
    user = flexmock("user", :facebook_id => "5678")
    assert_equal "<fb:if-is-user uid=\"5678\"></fb:if-is-user>", @h.fb_if_is_user(user){}    
  end
  
  def test_fb_if_is_user_with_array
    user1 = flexmock("user", :facebook_id => "5678")
    user2 = flexmock("user", :facebook_id => "1234")
    assert_equal "<fb:if-is-user uid=\"5678,1234\"></fb:if-is-user>", @h.fb_if_is_user([user1,user2]){}
  end
  
  def test_fb_else
    assert_equal "<fb:else></fb:else>", @h.fb_else{}    
  end
  
  def test_fb_about_url
    ENV["FACEBOOK_API_KEY"]="1234"
    assert_equal "http://www.facebook.com/apps/application.php?api_key=1234", @h.fb_about_url
  end
  
  def test_fb_ref_with_url
    assert_equal "<fb:ref url=\"A URL\" />", @h.fb_ref(:url => "A URL")
  end
  
  def test_fb_ref_with_handle
    assert_equal "<fb:ref handle=\"A Handle\" />", @h.fb_ref(:handle => "A Handle")
  end
  
  def test_fb_ref_with_invalid_attribute
    assert_raises(ArgumentError) {@h.fb_ref(:handlee => "A HANLDE")}
  end
  
  def test_fb_ref_with_handle_and_url
    assert_raises(ArgumentError) {@h.fb_ref(:url => "URL", :handle => "HANDLE")}
  end  
  
  def test_facebook_messages_notice
    @h.flash[:notice]="A message"
    assert_equal "<fb:success message=\"A message\" />",@h.facebook_messages
  end
  
  def test_facebook_messages_error
    @h.flash[:error]="An error"
    assert_equal "<fb:error message=\"An error\" />",@h.facebook_messages
  end
  def test_fb_wall_post
    assert_equal "<fb:wallpost uid=\"1234\">A wall post</fb:wallpost>",@h.fb_wall_post("1234","A wall post")
  end
  
  def test_fb_pronoun
    assert_equal "<fb:pronoun uid=\"1234\"></fb:pronoun>", @h.fb_pronoun(1234)
  end
  
  def test_fb_pronoun_with_transformed_key
    assert_equal "<fb:pronoun uid=\"1234\" usethey=\"true\"></fb:pronoun>", @h.fb_pronoun(1234, :use_they => true)
  end
  
  def test_fb_pronoun_with_user_responding_to_facebook_id
    user = flexmock("user", :facebook_id => "5678")
    assert_equal "<fb:pronoun uid=\"5678\"></fb:pronoun>", @h.fb_pronoun(user)
  end
  
  def test_fb_pronoun_with_invalid_key
    assert_raises(ArgumentError) {@h.fb_pronoun(1234, :posessive => true)}
  end
  
  def test_fb_wall
    @h.expects(:capture).returns("wall content")
    @h.fb_wall do 
    end
    assert_equal "<fb:wall>wall content</fb:wall>",@h.output_buffer
  end
  
  def test_fb_multi_friend_request
    @h.expects(:capture).returns("body")
    @h.expects(:protect_against_forgery?).returns(false)
    @h.expects(:fb_multi_friend_selector).returns("friend selector")
    assert_equal "<fb:request-form action=\"action\" content=\"body\" invite=\"true\" method=\"post\" type=\"invite\">friend selector</fb:request-form>",
      (@h.fb_multi_friend_request("invite","ignored","action") {})
  end
  
  def test_fb_multi_friend_request_with_protection_against_forgery
    @h.expects(:capture).returns("body")
    @h.expects(:protect_against_forgery?).returns(true)
    @h.expects(:request_forgery_protection_token).returns('forgery_token')
    @h.expects(:form_authenticity_token).returns('form_token')

    @h.expects(:fb_multi_friend_selector).returns("friend selector")
    assert_equal "<fb:request-form action=\"action\" content=\"body\" invite=\"true\" method=\"post\" type=\"invite\">friend selector<input name=\"forgery_token\" type=\"hidden\" value=\"form_token\" /></fb:request-form>",
      (@h.fb_multi_friend_request("invite","ignored","action") {})
  end
  
  def test_fb_dialog
    @h.expects(:capture).returns("dialog content")
    @h.fb_dialog( "my_dialog", "1" ) do
    end
    assert_equal '<fb:dialog cancel_button="1" id="my_dialog">dialog content</fb:dialog>', @h.output_buffer
  end
  def test_fb_dialog_title
    assert_equal '<fb:dialog-title>My Little Dialog</fb:dialog-title>', @h.fb_dialog_title("My Little Dialog")
  end
  def test_fb_dialog_content
    @h.expects(:capture).returns("dialog content content")
    @h.fb_dialog_content do
    end
    assert_equal '<fb:dialog-content>dialog content content</fb:dialog-content>', @h.output_buffer
  end
  def test_fb_dialog_button
    assert_equal '<fb:dialog-button clickrewriteform="my_form" clickrewriteid="my_dialog" clickrewriteurl="http://www.some_url_here.com/dialog_return.php" type="submit" value="Yes" />',
      @h.fb_dialog_button("submit", "Yes", {:clickrewriteurl => "http://www.some_url_here.com/dialog_return.php",
                                            :clickrewriteid => "my_dialog", :clickrewriteform => "my_form" } )
  end
  
  def test_fb_request_form
    @h.expects(:capture).returns("body")
    @h.expects(:protect_against_forgery?).returns(false)
    assert_equal "<fb:request-form action=\"action\" content=\"Test Param\" invite=\"true\" method=\"post\" type=\"invite\">body</fb:request-form>",
      (@h.fb_request_form("invite","test_param","action") {})
  end

  def test_fb_request_form_with_protect_against_forgery
    @h.expects(:capture).returns("body")
    @h.expects(:protect_against_forgery?).returns(true)
    @h.expects(:request_forgery_protection_token).returns('forgery_token')
    @h.expects(:form_authenticity_token).returns('form_token')
    assert_equal "<fb:request-form action=\"action\" content=\"Test Param\" invite=\"true\" method=\"post\" type=\"invite\">body<input name=\"forgery_token\" type=\"hidden\" value=\"form_token\" /></fb:request-form>",
      (@h.fb_request_form("invite","test_param","action") {})
  end
  
  def test_fb_error_with_only_message
    assert_equal "<fb:error message=\"Errors have occurred!!\" />", @h.fb_error("Errors have occurred!!")
  end

  def test_fb_error_with_message_and_text
    assert_equal "<fb:error><fb:message>Errors have occurred!!</fb:message>Label can't be blank!!</fb:error>", @h.fb_error("Errors have occurred!!", "Label can't be blank!!")
  end

  def test_fb_explanation_with_only_message
    assert_equal "<fb:explanation message=\"This is an explanation\" />", @h.fb_explanation("This is an explanation")
  end

  def test_fb_explanation_with_message_and_text
    assert_equal "<fb:explanation><fb:message>This is an explanation</fb:message>You have a match</fb:explanation>", @h.fb_explanation("This is an explanation", "You have a match")
  end

  def test_fb_success_with_only_message
    assert_equal "<fb:success message=\"Woot!!\" />", @h.fb_success("Woot!!")
  end

  def test_fb_success_with_message_and_text
    assert_equal "<fb:success><fb:message>Woot!!</fb:message>You Rock!!</fb:success>", @h.fb_success("Woot!!", "You Rock!!")
  end
  
  def test_facebook_form_for
    @h.expects(:protect_against_forgery?).returns(false)
    form_body=@h.facebook_form_for(:model,:url=>"action") do
    end
    assert_equal "<fb:editor action=\"action\"></fb:editor>",form_body
  end
  
  def test_facebook_form_for_with_authenticity_token
    @h.expects(:protect_against_forgery?).returns(true)
    @h.expects(:request_forgery_protection_token).returns('forgery_token')
    @h.expects(:form_authenticity_token).returns('form_token')
    assert_equal "<fb:editor action=\"action\"><input name=\"forgery_token\" type=\"hidden\" value=\"form_token\" /></fb:editor>",
      (@h.facebook_form_for(:model, :url => "action") {})
  end
  
  def test_fb_friend_selector
    assert_equal("<fb:friend-selector />",@h.fb_friend_selector)
  end
  
  def test_fb_request_form_submit
    assert_equal("<fb:request-form-submit />",@h.fb_request_form_submit)  
  end   

	def test_fb_request_form_submit_with_uid
    assert_equal("<fb:request-form-submit uid=\"123456789\" />",@h.fb_request_form_submit({:uid => "123456789"}))
  end

  def test_fb_request_form_submit_with_label
    assert_equal("<fb:request-form-submit label=\"Send Invite to Joel\" />",@h.fb_request_form_submit({:label => "Send Invite to Joel"}))
  end

  def test_fb_request_form_submit_with_uid_and_label
    assert_equal("<fb:request-form-submit label=\"Send Invite to Joel\" uid=\"123456789\" />",@h.fb_request_form_submit({:uid =>"123456789", :label => "Send Invite to Joel"}))
  end
  
  def test_fb_action
    assert_equal "<fb:action href=\"/growingpets/rub\">Rub my pet</fb:action>", @h.fb_action("Rub my pet", "/growingpets/rub")  
  end
  
  def test_fb_help
    assert_equal "<fb:help href=\"http://www.facebook.com/apps/application.php?id=6236036681\">Help</fb:help>", @h.fb_help("Help", "http://www.facebook.com/apps/application.php?id=6236036681")      
  end
  
  def test_fb_create_button
    assert_equal "<fb:create-button href=\"/growingpets/invite\">Invite Friends</fb:create-button>", @h.fb_create_button('Invite Friends', '/growingpets/invite')
  end

  def test_fb_comments_a_1
    assert_equal "<fb:comments candelete=\"false\" canpost=\"true\" numposts=\"7\" showform=\"true\" xid=\"a:1\"></fb:comments>", @h.fb_comments("a:1",true,false,7,:showform=>true)
  end

  def test_fb_comments_xxx
    assert_equal "<fb:comments candelete=\"false\" canpost=\"true\" numposts=\"4\" optional=\"false\" xid=\"xxx\"></fb:comments>", @h.fb_comments("xxx",true,false,4,:optional=>false)
  end

  def test_fb_comments_with_title
    assert_equal "<fb:comments candelete=\"false\" canpost=\"true\" numposts=\"4\" optional=\"false\" xid=\"xxx\"><fb:title>TITLE</fb:title></fb:comments>", @h.fb_comments("xxx",true,false,4,:optional=>false, :title => "TITLE") 
  end
  def test_fb_board
    assert_equal "<fb:board optional=\"false\" xid=\"xxx\"></fb:board>", @h.fb_board("xxx",:optional => false) 
  end
  def test_fb_board_with_title
    assert_equal "<fb:board optional=\"false\" xid=\"xxx\"><fb:title>TITLE</fb:title></fb:board>", @h.fb_board("xxx",:optional=>false, :title => "TITLE") 
  end
  
  def test_fb_dashboard
    @h.expects(:capture).returns("dashboard content")
    @h.fb_dashboard do 
    end
    assert_equal "<fb:dashboard>dashboard content</fb:dashboard>", @h.output_buffer
  end
  def test_fb_dashboard_non_block
    assert_equal "<fb:dashboard></fb:dashboard>", @h.fb_dashboard
  end
  
  def test_fb_wide
    @h.expects(:capture).returns("wide profile content")
    @h.fb_wide do
    end
    assert_equal "<fb:wide>wide profile content</fb:wide>", @h.output_buffer
  end
  
  def test_fb_narrow
    @h.expects(:capture).returns("narrow profile content")
    @h.fb_narrow do
    end
    assert_equal "<fb:narrow>narrow profile content</fb:narrow>", @h.output_buffer
  end  
  
  def test_fb_login_button
    assert_equal "<fb:login-button onlogin=\"somejs\"></fb:login-button>",@h.fb_login_button("somejs")
  end
  
  def test_init_fb_connect_no_features
    assert ! @h.init_fb_connect.match(/XFBML/)
  end
  
  def test_init_fb_connect_with_features
    assert @h.init_fb_connect("XFBML").match(/XFBML/)
  end

  def test_init_fb_connect_receiver_path
    assert @h.init_fb_connect.match(/xd_receiver.html/)
  end

  def test_init_fb_connect_receiver_path_ssl
    @h.instance_eval do
      def request
        ssl_request = ActionController::TestRequest.new
        ssl_request.stubs(:ssl?).returns(true)
        ssl_request
      end
    end

    assert @h.init_fb_connect.match(/xd_receiver_ssl.html/)
  end

  def test_init_fb_connect_with_features_and_body
    @h.expects(:capture).returns("Body Content")
    
    __in_erb_template = true

    @h.init_fb_connect("XFBML") do
    end
    assert @h.output_buffer =~ /Body Content/
  end

  def test_init_fb_connect_no_options
    assert ! @h.init_fb_connect.match(/Element.observe\(window,'load',/)
  end
  
  def test_init_fb_connect_with_options_js_jquery
    assert ! @h.init_fb_connect(:js => :jquery).match(/\$\(document\).ready\(/)
  end
  
  def test_init_fb_connect_with_features_and_options_js_jquery
    assert @h.init_fb_connect("XFBML", :js => :jquery).match(/XFBML.*/)
    assert @h.init_fb_connect("XFBML", :js => :jquery).match(/\$\(document\).ready\(/)
  end

  def test_init_fb_connect_without_options_app_settings
    assert @h.init_fb_connect().match(/, \{\}\)/)
  end
  
  def test_init_fb_connect_with_options_app_settings
    assert @h.init_fb_connect(:app_settings => "{foo: bar}").match(/, \{foo: bar\}\)/)
  end
  
  
  def test_fb_login_and_redirect
    assert_equal @h.fb_login_and_redirect("/path"),"<fb:login-button onlogin=\"window.location.href = &quot;/path&quot;;\"></fb:login-button>"
  end
  
  def test_fb_logout_link
    assert_equal @h.fb_logout_link("Logout","My URL"),"<a href=\"#\" onclick=\"FB.Connect.logoutAndRedirect(&quot;My URL&quot;);; return false;\">Logout</a>"
  end

  def test_fb_user_action_with_literal_callback
    action = Facebooker::Rails::Publisher::UserAction.new
    assert_equal "FB.Connect.showFeedDialog(null, null, null, null, null, FB.RequireConnect.promptConnect, function() {alert('hi')}, \"prompt\", #{{"value" => "message"}.to_json});",
                 @h.fb_user_action(action,"message","prompt","function() {alert('hi')}")
  end

  def test_fb_user_action_with_nil_callback
    action = Facebooker::Rails::Publisher::UserAction.new
    assert_equal "FB.Connect.showFeedDialog(null, null, null, null, null, FB.RequireConnect.promptConnect, null, \"prompt\", #{{"value" => "message"}.to_json});",
                 @h.fb_user_action(action,"message","prompt")
  end


  def test_fb_connect_javascript_tag
    silence_warnings do
      assert_equal "<script src=\"http://static.ak.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php\" type=\"text/javascript\"></script>",
        @h.fb_connect_javascript_tag
    end
  end

  def test_fb_connect_javascript_tag_with_language_option
    silence_warnings do
      assert_equal "<script src=\"http://static.ak.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php/en_US\" type=\"text/javascript\"></script>",
        @h.fb_connect_javascript_tag(:lang => "en_US")
    end
  end

  def test_fb_connect_javascript_tag_ssl
    @h.instance_eval do
      def request
        ssl_request = ActionController::TestRequest.new
        ssl_request.stubs(:ssl?).returns(true)
        ssl_request
      end
    end

    silence_warnings do
      assert_equal "<script src=\"https://www.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php\" type=\"text/javascript\"></script>",
        @h.fb_connect_javascript_tag
    end
  end

  def test_fb_connect_javascript_tag_ssl_with_language_option
    @h.instance_eval do
      def request
        ssl_request = ActionController::TestRequest.new
        ssl_request.stubs(:ssl?).returns(true)
        ssl_request
      end
    end

    silence_warnings do
      assert_equal "<script src=\"https://www.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php/en_US\" type=\"text/javascript\"></script>",
        @h.fb_connect_javascript_tag(:lang => "en_US")
    end
  end

  def test_fb_container
    @h.expects(:capture).returns("Inner Stuff")
    @h.fb_container(:condition=>"somejs") do
    end
    assert_equal "<fb:container condition=\"somejs\">Inner Stuff</fb:container>",@h.output_buffer
  end
  
  def test_fb_eventlink
    assert_equal '<fb:eventlink eid="21150032416"></fb:eventlink>',@h.fb_eventlink("21150032416")
  end
  
  def test_fb_grouplink
    assert_equal '<fb:grouplink gid="2541896821"></fb:grouplink>',@h.fb_grouplink("2541896821")
  end
  
  def test_fb_serverfbml
    @h.expects(:capture).returns("Inner Stuff")
    @h.fb_serverfbml(:condition=>"somejs") do
    end
    assert_equal "<fb:serverfbml condition=\"somejs\">Inner Stuff</fb:serverfbml>",@h.output_buffer
  end
  
  def test_fb_share_button
    assert_equal "<fb:share-button class=\"url\" href=\"http://www.elevatedrails.com\"></fb:share-button>",@h.fb_share_button("http://www.elevatedrails.com")
  end
  
  def test_fb_unconnected_friends_count_without_condition
    assert_equal "<fb:unconnected-friends-count></fb:unconnected-friends-count>",@h.fb_unconnected_friends_count
  end
  
  def test_fb_user_status
    user=flexmock("user", :facebook_id => "5678")
    assert_equal '<fb:user-status linked="false" uid="5678"></fb:user-status>',@h.fb_user_status(user,false)
  end
  
  def test_fb_time
    time = Time.now
    assert_equal %Q{<fb:time preposition="true" t="#{time.to_i}" tz="America/New York" />}, @h.fb_time(time, :tz => 'America/New York', :preposition => true)
  end
  
  def test_fb_time_defaults
    time = Time.now
    assert_equal %Q{<fb:time t="#{time.to_i}" />}, @h.fb_time(time)
  end
end
class TestModel
  attr_accessor :name,:facebook_id
end

class RailsFacebookFormbuilderTest < Test::Unit::TestCase
  class TestTemplate
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::CaptureHelper
    include ActionView::Helpers::TagHelper
    include Facebooker::Rails::Helpers
    attr_accessor :output_buffer
    def initialize
      @output_buffer=""
    end
  end
  def setup
    @_erbout = ""
    @test_model = TestModel.new
    @test_model.name="Mike"
    @template = TestTemplate.new
    @proc = Proc.new {}
    @form_builder = Facebooker::Rails::FacebookFormBuilder.new(:test_model,@test_model,@template,{},@proc)
    def @form_builder._erbout
      ""
    end
    
  end
  
  def test_text_field
    assert_equal "<fb:editor-text id=\"test_model_name\" label=\"Name\" name=\"test_model[name]\" value=\"Mike\"></fb:editor-text>",
        @form_builder.text_field(:name)
  end
  def test_text_area
    assert_equal "<fb:editor-textarea id=\"test_model_name\" label=\"Name\" name=\"test_model[name]\">Mike</fb:editor-textarea>",
        @form_builder.text_area(:name)    
  end
  
  def test_default_name_and_id
    assert_equal "<fb:editor-text id=\"different_id\" label=\"Name\" name=\"different_name\" value=\"Mike\"></fb:editor-text>",
        @form_builder.text_field(:name, {:name => 'different_name', :id => 'different_id'})
  end
  
  def test_collection_typeahead
    flexmock(@form_builder) do |fb|
      fb.should_receive(:collection_typeahead_internal).with(:name,["ABC"],:size,:to_s,{})
    end
    @form_builder.collection_typeahead(:name,["ABC"],:size,:to_s)        
  end
  
  def test_collection_typeahead_internal
    assert_equal "<fb:typeahead-input id=\"test_model_name\" name=\"test_model[name]\" value=\"Mike\"><fb:typeahead-option value=\"3\">ABC</fb:typeahead-option></fb:typeahead-input>",
      @form_builder.collection_typeahead_internal(:name,["ABC"],:size,:to_s)        
  end
  
  def test_buttons
    @form_builder.expects(:create_button).with(:first).returns("first")
    @form_builder.expects(:create_button).with(:second).returns("second")
    @template.expects(:content_tag).with("fb:editor-buttonset","firstsecond")
    @form_builder.buttons(:first,:second)    
  end
  
  def test_create_button
    assert_equal "<fb:editor-button name=\"commit\" value=\"first\"></fb:editor-button>",@form_builder.create_button(:first)
  end
  
  def test_custom
    @template.expects(:password_field).returns("password_field")
    assert_equal "<fb:editor-custom label=\"Name\">password_field</fb:editor-custom>",@form_builder.password_field(:name)
  end
  
  def test_text
    assert_equal "<fb:editor-custom label=\"custom\">Mike</fb:editor-custom>",@form_builder.text("Mike",:label=>"custom")
  end
  
  def test_multi_friend_input
    assert_equal "<fb:editor-custom label=\"Friends\"><fb:multi-friend-input></fb:multi-friend-input></fb:editor-custom>",@form_builder.multi_friend_input
  end
  

end

class RailsPrettyErrorsTest < Test::Unit::TestCase
  class ControllerWhichFails < ActionController::Base
    def pass
      render :text=>''
    end
    def fail
      raise "I'm failing"
    end
  end
  
  def setup
    Facebooker.apply_configuration('api_key'=>"1234", 'secret_key'=>"34278",'canvas_page_name'=>'mike','pretty_errors'=>true)
    @controller = ControllerWhichFails.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_pretty_errors_disabled_success
    post :pass, facebook_params
    assert_response 200
  end

  def test_pretty_errors_disabled_error
    Facebooker.apply_configuration('api_key'=>"1234", 'secret_key'=>"34278",'canvas_page_name'=>'mike','pretty_errors'=>false)
    silence_warnings do
      post :fail, facebook_params
    end
    assert_response :error
  end

  def test_pretty_errors_enabled_success
    post :pass, facebook_params
    assert_response 200
  end
  def test_pretty_errors_enabled_error
    silence_warnings do
      post :fail, facebook_params
    end
    assert_response 200
  end
end

class RailsUrlHelperExtensionsTest < Test::Unit::TestCase
  class UrlHelperExtensionsClass
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TagHelper
    def initialize(controller)
      @controller = controller
    end

    def protect_against_forgery?
       false
    end
    
    def request_comes_from_facebook?
      @request_comes_from_facebook
    end
    
    def request_comes_from_facebook=(val)
      @request_comes_from_facebook = val
    end

  end 
  class UrlHelperExtensionsController < NoisyController    
    def index
      render :nothing => true
    end
    def do_it
      render :nothing => true
    end
  end

  class FacebookRequest < ActionController::TestRequest  
  end

  def setup
    @controller = UrlHelperExtensionsController.new
    @request    = FacebookRequest.new
    @response   = ActionController::TestResponse.new

    @u = UrlHelperExtensionsClass.new(@controller)
    @u.request_comes_from_facebook = true
    
    @non_canvas_u = UrlHelperExtensionsClass.new(@controller)
    @non_canvas_u.request_comes_from_facebook = false
    
    @label = "Testing"
    @url = "test.host"
    @prompt = "Are you sure?"
    @default_title = "Please Confirm"
    @title = "Confirm Request"
    @style = {:color => 'black', :background => 'white'}
    @verbose_style = "{background: 'white', color: 'black'}"
    @default_okay = "Okay"
    @default_cancel = "Cancel"
    @default_style = "" #"'width','200px'"
  end

  def test_link_to
    assert_equal "<a href=\"#{@url}\">Testing</a>", @u.link_to(@label, @url)
  end

  def test_link_to_with_popup
    assert_raises(ActionView::ActionViewError) {@u.link_to(@label,@url, :popup=>true)}
  end

  def test_link_to_with_confirm
    assert_dom_equal( "<a href=\"#{@url}\" onclick=\"var dlg = new Dialog().showChoice(\'#{@default_title}\',\'#{@prompt}\',\'#{@default_okay}\',\'#{@default_cancel}\').setStyle(#{@default_style});"+
                 "var a=this;dlg.onconfirm = function() { " + 
                 "document.setLocation(a.getHref()); };return false;\">#{@label}</a>",
                  @u.link_to(@label, @url, :confirm => @prompt) )
  end
  def test_link_to_with_confirm_with_title
    assert_dom_equal( "<a href=\"#{@url}\" onclick=\"var dlg = new Dialog().showChoice(\'#{@title}\',\'#{@prompt}\',\'#{@default_okay}\',\'#{@default_cancel}\').setStyle(#{@default_style});"+
                 "var a=this;dlg.onconfirm = function() { " + 
                 "document.setLocation(a.getHref()); };return false;\">#{@label}</a>",
                  @u.link_to(@label, @url, :confirm => {:title=>@title,:content=>@prompt}) )
  end
  def test_link_to_with_confirm_with_title_and_style
    assert_dom_equal( "<a href=\"#{@url}\" onclick=\"var dlg = new Dialog().showChoice(\'#{@title}\',\'#{@prompt}\',\'#{@default_okay}\',\'#{@default_cancel}\').setStyle(#{@verbose_style});"+
                 "var a=this;dlg.onconfirm = function() { " + 
                 "document.setLocation(a.getHref()); };return false;\">#{@label}</a>",
                  @u.link_to(@label, @url, :confirm => {:title=>@title,:content=>@prompt}.merge!(@style)) )
  end

  def test_link_to_with_method
    assert_dom_equal( "<a href=\"#{@url}\" onclick=\"var a=this;var f = document.createElement('form'); f.setStyle('display','none'); "+
                 "a.getParentNode().appendChild(f); f.setMethod('POST'); f.setAction(a.getHref());" +
                 "var m = document.createElement('input'); m.setType('hidden'); "+
                 "m.setName('_method'); m.setValue('delete'); f.appendChild(m);"+
                 "f.submit();return false;\">#{@label}</a>", @u.link_to(@label,@url, :method=>:delete))
  end

  def test_link_to_with_confirm_and_method
    assert_dom_equal( "<a href=\"#{@url}\" onclick=\"var dlg = new Dialog().showChoice(\'#{@default_title}\',\'#{@prompt}\',\'#{@default_okay}\',\'#{@default_cancel}\').setStyle(#{@default_style});"+
                 "var a=this;dlg.onconfirm = function() { " + 
                 "var f = document.createElement('form'); f.setStyle('display','none'); "+
                 "a.getParentNode().appendChild(f); f.setMethod('POST'); f.setAction(a.getHref());" +
                 "var m = document.createElement('input'); m.setType('hidden'); "+
                 "m.setName('_method'); m.setValue('delete'); f.appendChild(m);"+
                 "f.submit(); };return false;\">#{@label}</a>", @u.link_to(@label,@url, :confirm=>@prompt, :method=>:delete) )
  end
  def test_link_to_with_confirm_and_method_for_non_canvas_page
    assert_dom_equal( "<a href=\"#{@url}\" onclick=\"if (confirm(\'#{@prompt}\')) { var f = document.createElement('form'); f.style.display = 'none'; "+
                      "this.parentNode.appendChild(f); f.method = 'POST'; f.action = this.href;var m = document.createElement('input'); "+
                      "m.setAttribute('type', 'hidden'); m.setAttribute('name', '_method'); m.setAttribute('value', 'delete'); "+
                      "f.appendChild(m);f.submit(); };return false;\">#{@label}</a>",
                      @non_canvas_u.link_to(@label,@url, :confirm=>@prompt, :method=>:delete) )
  end

  def test_button_to
    assert_equal "<form method=\"post\" action=\"#{@url}\" class=\"button-to\"><div>" +
                 "<input type=\"submit\" value=\"#{@label}\" /></div></form>", @u.button_to(@label,@url)
  end

  def test_button_to_with_confirm
    assert_equal "<form method=\"post\" action=\"#{@url}\" class=\"button-to\"><div>" +
                 "<input onclick=\"var dlg = new Dialog().showChoice(\'#{@default_title}\',\'#{@prompt}\',\'#{@default_okay}\',\'#{@default_cancel}\').setStyle(#{@default_style});"+
                 "var a=this;dlg.onconfirm = function() { "+
                 "a.getForm().submit(); };return false;\" type=\"submit\" value=\"#{@label}\" /></div></form>", 
                 @u.button_to(@label,@url, :confirm=>@prompt)
  end
  def test_button_to_with_confirm_for_non_canvas_page
    assert_equal "<form method=\"post\" action=\"#{@url}\" class=\"button-to\"><div>"+
                 "<input onclick=\"return confirm(\'#{@prompt}\');\" type=\"submit\" value=\"#{@label}\" /></div></form>",
                 @non_canvas_u.button_to(@label,@url, :confirm=>@prompt)
  end

  def test_link_to_unless_with_true
       assert_equal @label, @u.link_to_unless(true,@label,@url)
  end
  def test_link_to_unless_with_false
       assert_equal @u.link_to(@label,@url), @u.link_to_unless(false,@label,@url)
  end

  def test_link_to_if_with_true
       assert_equal @u.link_to(@label,@url), @u.link_to_if(true,@label,@url)
  end
  def test_link_to_if_with_false
       assert_equal @label, @u.link_to_if(false,@label,@url)
  end
  
end

class RailsRequestFormatTest < Test::Unit::TestCase
  class FacebookController < NoisyController
    def index
      respond_to do |format|
        format.html { render :text => 'html' }
        format.fbml { render :text => 'fbml' }
        format.fbjs { render :text => 'fbjs' }
      end
    end
  end
  
  def setup
    Facebooker.apply_configuration({
      'api_key'          => '1234567',
      'canvas_page_name' => 'facebook_app_name',
      'secret_key'       => '7654321' })
    @controller = FacebookController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @controller.stubs(:verify_signature).returns(true)
  end
  
  def test_responds_to_html_without_canvas
    get :index
    assert_equal 'html', @response.body
  end

  def test_responds_to_fbml_in_canvas
    get :index, facebook_params(:fb_sig_in_canvas => '1')
    assert_equal 'fbml', @response.body
  end

  def test_responds_to_fbjs_when_is_ajax
    get :index, facebook_params(:fb_sig_is_ajax => '1')
    assert_equal 'fbjs', @response.body
  end
  
  def test_responds_to_html_when_iframe
    get :index, facebook_params(:fb_sig_in_iframe => '1')
    assert_equal 'html', @response.body
  end
  
end
