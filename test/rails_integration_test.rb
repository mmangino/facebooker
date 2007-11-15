require File.dirname(__FILE__) + '/test_helper.rb'
begin
  require 'action_controller'
  require 'action_controller/test_process'
  require 'facebooker/rails/controller'
  require 'facebooker/rails/helpers'
  require 'facebooker/rails/facebook_form_builder'
  require File.dirname(__FILE__)+'/../init'
  require 'mocha'
  ActionController::Routing::Routes.draw do |map|
    map.connect 'require_auth/:action', :controller => "controller_which_requires_facebook_authentication"
    map.connect 'require_install/:action', :controller => "controller_which_requires_application_installation"
  end  
  class NoisyController < ActionController::Base
    include Facebooker::Rails::Controller
    def rescue_action(e) raise e end
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
    
  end
  class ControllerWhichRequiresApplicationInstallation < NoisyController
    ensure_application_is_installed_by_facebook_user
    def index
      render :text => 'installed!'
    end    
  end

class RailsIntegrationTestForApplicationInstallation < Test::Unit::TestCase
  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'
    @controller = ControllerWhichRequiresApplicationInstallation.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_if_controller_requires_application_installation_unauthenticated_requests_will_redirect_to_install_page
    get :index
    assert_response :redirect
    assert_equal("http://www.facebook.com/install.php?api_key=1234567&v=1.0", @response.headers['Location'])
  end
  
  def test_if_controller_requires_application_installation_authenticated_requests_without_installation_will_redirect_to_install_page
    get :index, example_rails_params_including_fb
    assert_response :success
    assert_equal("<fb:redirect url=\"http://www.facebook.com/install.php?api_key=1234567&v=1.0\" />", @response.body)
  end
  
  def test_if_controller_requires_application_installation_authenticated_requests_with_installation_will_render
    get :index, example_rails_params_including_fb.merge('fb_sig_added' => "1")
    assert_response :success
    assert_equal("installed!", @response.body)
  end

  private
    def example_rails_params_including_fb
      {"fb_sig_time"=>"1186588275.5988", "fb_sig"=>"7371a6400329b229f800a5ecafe03b0a", "action"=>"index", "fb_sig_in_canvas"=>"1", "fb_sig_session_key"=>"c452b5d5d60cbd0a0da82021-744961110", "controller"=>"controller_which_requires_facebook_authentication", "fb_sig_expires"=>"0", "fb_sig_friends"=>"417358,702720,1001170,1530839,3300204,3501584,6217936,9627766,9700907,22701786,33902768,38914148,67400422,135301144,157200364,500103523,500104930,500870819,502149612,502664898,502694695,502852293,502985816,503254091,504510130,504611551,505421674,509229747,511075237,512548373,512830487,517893818,517961878,518890403,523589362,523826914,525812984,531555098,535310228,539339781,541137089,549405288,552706617,564393355,564481279,567640762,568091401,570201702,571469972,573863097,574415114,575543081,578129427,578520568,582262836,582561201,586550659,591631962,592318318,596269347,596663221,597405464,599764847,602995438,606661367,609761260,610544224,620049417,626087078,628803637,632686250,641422291,646763898,649678032,649925863,653288975,654395451,659079771,661794253,665861872,668960554,672481514,675399151,678427115,685772348,686821151,687686894,688506532,689275123,695551670,710631572,710766439,712406081,715741469,718976395,719246649,722747311,725327717,725683968,725831016,727580320,734151780,734595181,737944528,748881410,752244947,763868412,768578853,776596978,789728437,873695441", "fb_sig_added"=>"0", "fb_sig_api_key"=>"b6c9c857ac543ca806f4d3187cd05e09", "fb_sig_user"=>"744961110", "fb_sig_profile_update_time"=>"1180712453"}
    end
end
  
class RailsIntegrationTest < Test::Unit::TestCase
  def setup
    ENV['FACEBOOKER_RELATIVE_URL_ROOT'] ='root'
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'
    @controller = ControllerWhichRequiresFacebookAuthentication.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new    
  end

  def test_if_controller_requires_facebook_authentication_unauthenticated_requests_will_redirect
    get :index
    assert_response :redirect
    assert_equal("http://www.facebook.com/login.php?api_key=1234567&v=1.0", @response.headers['Location'])
  end

  def test_facebook_params_are_parsed_into_a_separate_hash
    get :index, example_rails_params_including_fb
    facebook_params = @controller.facebook_params
    assert_equal([8, 8], [facebook_params['time'].day, facebook_params['time'].mon])
  end
  
  def test_facebook_params_convert_in_canvas_to_boolean
    get :index, example_rails_params_including_fb
    assert_equal(true, @controller.facebook_params['in_canvas'])    
  end
  
  def test_facebook_params_convert_added_to_boolean_false
    get :index, example_rails_params_including_fb
    assert_equal(false, @controller.facebook_params['added'])
  end
  
  def test_facebook_params_convert_added_to_boolean_true
    get :index, example_rails_params_including_fb.merge('fb_sig_added' => "1")
    assert_equal(true, @controller.facebook_params['added'])
  end
  
  def test_facebook_params_convert_expirey_into_time_or_nil
    get :index, example_rails_params_including_fb
    assert_nil(@controller.facebook_params['expires'])
    modified_params = example_rails_params_including_fb
    modified_params['fb_sig_expires'] = modified_params['fb_sig_time']
    setup # reset session and cached params
    get :index, modified_params
    assert_equal([8, 8], [@controller.facebook_params['time'].day, @controller.facebook_params['time'].mon])    
  end
  
  def test_facebook_params_convert_friend_list_to_parsed_array_of_friend_ids
    get :index, example_rails_params_including_fb
    assert_kind_of(Array, @controller.facebook_params['friends'])    
    assert_equal(111, @controller.facebook_params['friends'].size)
  end
  
  def test_session_can_be_resecured_from_facebook_params
    get :index, example_rails_params_including_fb
    assert_equal(744961110, @controller.facebook_session.user.id)    
  end
  
  def test_existing_secured_session_is_used_if_available
    session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY'])
    session.secure_with!("a session key", "1111111", Time.now.to_i + 60)
    get :index, example_rails_params_including_fb, {:facebook_session => session}
    assert_equal(1111111, @controller.facebook_session.user.id)
  end
  
  def test_session_can_be_secured_with_auth_token
    auth_token = 'ohaiauthtokenhere111'
    modified_params = example_rails_params_including_fb
    modified_params.delete('fb_sig_session_key')
    modified_params['auth_token'] = auth_token
    session_mock = flexmock(session = Facebooker::Session.create(ENV['FACEBOOK_API_KEY'], ENV['FACEBOOK_SECRET_KEY']))
    session_mock.should_receive(:post).with('facebook.auth.getSession', :auth_token => auth_token).once.and_return({}).ordered
    flexmock(@controller).should_receive(:new_facebook_session).once.and_return(session).ordered
    get :index, modified_params
  end
  
  def test_user_friends_can_be_populated_from_facebook_params_if_available
    get :index, example_rails_params_including_fb
    assert_not_nil(friends = @controller.facebook_session.user.instance_variable_get("@friends"))
    assert_equal(111, friends.size)    
  end
  
  def test_fbml_redirect_tag_handles_hash_parameters_correctly
    get :index, example_rails_params_including_fb
    assert_equal "<fb:redirect url=\"http://apps.facebook.com/root/require_auth\" />", @controller.send(:fbml_redirect_tag, :action => :index)
  end
  
  def test_redirect_to_renders_fbml_redirect_tag_if_request_is_for_a_facebook_canvas
    get :index, example_rails_params_including_fb_for_user_not_logged_into_application
    assert_response :success
    assert_equal("<fb:redirect url=\"http://www.facebook.com/login.php?api_key=1234567&v=1.0\" />", @response.body)
  end
  
  def test_url_for_links_to_canvas_if_canvas_is_true_and_not_in_canvas
    get :link_test,example_rails_params_including_fb.merge(:fb_sig_in_canvas=>0,:canvas=>true)
    assert_match /apps.facebook.com/,@response.body
  end
  
  def test_includes_relative_url_root_when_linked_to_canvas
    get :link_test,example_rails_params_including_fb.merge(:fb_sig_in_canvas=>0,:canvas=>true)
    assert_match /root/,@response.body
  end

  def test_url_for_links_to_callback_if_canvas_is_false_and_in_canvas
    get :link_test,example_rails_params_including_fb.merge(:fb_sig_in_canvas=>0,:canvas=>false)
    assert_match /test.host/,@response.body
  end

  def test_url_for_doesnt_include_url_root_when_not_linked_to_canvas
    get :link_test,example_rails_params_including_fb.merge(:fb_sig_in_canvas=>0,:canvas=>false)
    assert !@response.body.match(/root/)
  end
  
  def test_url_for_links_to_canvas_if_canvas_is_not_set
    get :link_test,example_rails_params_including_fb
    assert_match /apps.facebook.com/,@response.body
  end
  
  private
  def example_rails_params_including_fb_for_user_not_logged_into_application
    {"fb_sig_time"=>"1186588275.5988", "fb_sig"=>"7371a6400329b229f800a5ecafe03b0a", "action"=>"index", "fb_sig_in_canvas"=>"1", "controller"=>"controller_which_requires_facebook_authentication", "fb_sig_added"=>"0", "fb_sig_api_key"=>"b6c9c857ac543ca806f4d3187cd05e09"}
  end
  
  def example_rails_params_including_fb
    {"fb_sig_time"=>"1186588275.5988", "fb_sig"=>"7371a6400329b229f800a5ecafe03b0a", "action"=>"index", "fb_sig_in_canvas"=>"1", "fb_sig_session_key"=>"c452b5d5d60cbd0a0da82021-744961110", "controller"=>"controller_which_requires_facebook_authentication", "fb_sig_expires"=>"0", "fb_sig_friends"=>"417358,702720,1001170,1530839,3300204,3501584,6217936,9627766,9700907,22701786,33902768,38914148,67400422,135301144,157200364,500103523,500104930,500870819,502149612,502664898,502694695,502852293,502985816,503254091,504510130,504611551,505421674,509229747,511075237,512548373,512830487,517893818,517961878,518890403,523589362,523826914,525812984,531555098,535310228,539339781,541137089,549405288,552706617,564393355,564481279,567640762,568091401,570201702,571469972,573863097,574415114,575543081,578129427,578520568,582262836,582561201,586550659,591631962,592318318,596269347,596663221,597405464,599764847,602995438,606661367,609761260,610544224,620049417,626087078,628803637,632686250,641422291,646763898,649678032,649925863,653288975,654395451,659079771,661794253,665861872,668960554,672481514,675399151,678427115,685772348,686821151,687686894,688506532,689275123,695551670,710631572,710766439,712406081,715741469,718976395,719246649,722747311,725327717,725683968,725831016,727580320,734151780,734595181,737944528,748881410,752244947,763868412,768578853,776596978,789728437,873695441", "fb_sig_added"=>"0", "fb_sig_api_key"=>"b6c9c857ac543ca806f4d3187cd05e09", "fb_sig_user"=>"744961110", "fb_sig_profile_update_time"=>"1180712453"}
  end
end

class RailsHelperTest < Test::Unit::TestCase
  class HelperClass
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::CaptureHelper
    include ActionView::Helpers::TagHelper
    include Facebooker::Rails::Helpers
    attr_accessor :flash
    def initialize
      @flash={}
      @template = self
      @content_for_test_param="Test Param"
    end
    #used for stubbing out the form builder
    def url_for(arg)
      arg
    end
    def fields_for(*args)
      ""
    end
    
  end 

  # used for capturing the contents of some of the helper tests
  # this duplicates the rails template system  
  attr_accessor :_erbout
  
  def setup
    @_erbout = ""
    @h = HelperClass.new
    ENV['FACEBOOKER_STATIC_HOST']='127.0.0.1:3000'
  end
  
  def test_fb_profile_pic
    assert_equal "<fb:profile-pic uid=\"1234\" />", @h.fb_profile_pic("1234")
  end

  def test_fb_profile_pic_with_valid_size
    assert_equal "<fb:profile-pic size=\"small\" uid=\"1234\" />", @h.fb_profile_pic("1234", :size => :small)
  end

  def test_fb_profile_pic_with_invalid_size
    assert_raises(ArgumentError) {@h.fb_profile_pic("1234", :size => :medium)}
  end
  
  def test_fb_name
    assert_equal "<fb:name uid=\"1234\" />",@h.fb_name("1234")
  end
  
  def test_fb_name_with_transformed_key
    assert_equal "<fb:name uid=\"1234\" useyou=\"true\" />", @h.fb_name(1234, :use_you => true)
  end
  
  def test_fb_name_with_user_responding_to_facebook_id
    user = flexmock("user", :facebook_id => "5678")
    assert_equal "<fb:name uid=\"5678\" />", @h.fb_name(user)
  end
  
  def test_fb_name_with_invalid_key
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
  
  def test_facebook_image_tag
    @h.expects(:image_path).with("test.jpg").returns("/test.jpg")
    assert_equal "<img src=\"http://127.0.0.1:3000/test.jpg\" />",@h.facebook_image_tag("test.jpg")
  end
  
  def test_fb_req_choice
    assert_equal "<fb:req-choice label=\"label\" url=\"url\" />", @h.fb_req_choice("label","url")
  end
  
  def test_fb_multi_friend_selector
    assert_equal "<fb:multi-friend-selector actiontext=\"This is a message\" max=\"20\" showborder=\"false\" />", @h.fb_multi_friend_selector("This is a message")
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
    assert_equal "<fb:pronoun uid=\"1234\" />", @h.fb_pronoun(1234)
  end
  
  def test_fb_pronoun_with_transformed_key
    assert_equal "<fb:pronoun uid=\"1234\" usethey=\"true\" />", @h.fb_pronoun(1234, :use_they => true)
  end
  
  def test_fb_pronoun_with_user_responding_to_facebook_id
    user = flexmock("user", :facebook_id => "5678")
    assert_equal "<fb:pronoun uid=\"5678\" />", @h.fb_pronoun(user)
  end
  
  def test_fb_pronoun_with_invalid_key
    assert_raises(ArgumentError) {@h.fb_pronoun(1234, :posessive => true)}
  end
  
  def test_fb_wall
    @h.expects(:capture).returns("wall content")
    @h.fb_wall do 
    end
    assert_equal "<fb:wall>wall content</fb:wall>",_erbout
  end
  
  def test_fb_multi_friend_request
    @h.expects(:capture).returns("body")
    @h.expects(:fb_multi_friend_selector).returns("friend selector")
    assert_equal "<fb:request-form action=\"action\" content=\"body\" invite=\"true\" method=\"post\" type=\"invite\">friend selector</fb:request-form>",
      (@h.fb_multi_friend_request("invite","ignored","action") {})
  end
  
  def test_fb_request_form
    @h.expects(:capture).returns("body")
    assert_equal "<fb:request-form action=\"action\" content=\"Test Param\" invite=\"true\" method=\"post\" type=\"invite\">body</fb:request-form>",
      (@h.fb_request_form("invite","test_param","action") {})
    
  end
  
  def test_fb_error_with_only_message
    assert_equal "<fb:error message=\"Errors have occurred!!\" />", @h.fb_error("Errors have occurred!!")
  end

  def test_fb_error_with_message_and_text
    assert_equal "<fb:error><fb:message>Errors have occurred!!</fb:message>Label can't be blank!!</fb:error>", @h.fb_error("Errors have occurred!!", "Label can't be blank!!")
  end

  def test_fb_success_with_only_message
    assert_equal "<fb:success message=\"Woot!!\" />", @h.fb_success("Woot!!")
  end

  def test_fb_success_with_message_and_text
    assert_equal "<fb:success><fb:message>Woot!!</fb:message>You Rock!!</fb:success>", @h.fb_success("Woot!!", "You Rock!!")
  end
  
  def test_facebook_form_for
    form_body=@h.facebook_form_for(:model,:url=>"action") do
    end
    assert_equal "<fb:editor action=\"action\"></fb:editor>",form_body
  end
  
  def test_fb_friend_selector
    assert_equal("<fb:friend-selector />",@h.fb_friend_selector)
  end
  
  def test_fb_request_form_submit
    assert_equal("<fb:request-form-submit />",@h.fb_request_form_submit)  
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
    attr_accessor :_erbout
    def initialize
      @_erbout=""
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
    assert_equal "<fb:editor-text id=\"testmodel_name\" label=\"Name\" name=\"testmodel[name]\" value=\"Mike\"></fb:editor-text>",
        @form_builder.text_field(:name)
  end
  def test_text_area
    assert_equal "<fb:editor-textarea id=\"testmodel_name\" label=\"Name\" name=\"testmodel[name]\">Mike</fb:editor-textarea>",
        @form_builder.text_area(:name)    
  end
  
  def test_buttons
    @form_builder.expects(:create_button).with(:first)
    @form_builder.expects(:create_button).with(:second)
    assert_equal "<fb:editor-buttonset></fb:editor-buttonset>",
        @form_builder.buttons(:first,:second)    
  end
  
  def test_create_button
    assert_equal "<fb:editor-button value=\"first\"></fb:editor-button>",@form_builder.create_button(:first)
  end
  
  def test_custom
    @template.expects(:password_field).returns("password_field")
    assert_equal "<fb:editor-custom label=\"Name\"></fb:editor-custom>",@form_builder.password_field(:name)
  end
  
  def test_multi_friend_input
    assert_equal "<fb:editor-custom label=\"Friends\"></fb:editor-custom>",@form_builder.multi_friend_input
  end
end
rescue LoadError
  $stderr.puts "Couldn't find action controller.  That's OK.  We'll skip it."
end