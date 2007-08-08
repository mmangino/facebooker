require File.dirname(__FILE__) + '/test_helper.rb'
begin
  require 'action_controller'
  require 'action_controller/test_process'
  require 'facebooker/rails/controller'
  ActionController::Routing::Routes.draw do |map|
    map.connect 'require_auth/:action', :controller => "controller_which_requires_facebook_authentication"
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
  end
class RailsIntegrationTest < Test::Unit::TestCase
  def setup
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
    assert_equal("Wed Aug 08 09:51:15 -0600 2007", facebook_params['time'].to_s)
  end
  
  def test_facebook_params_convert_in_canvas_to_boolean
    get :index, example_rails_params_including_fb
    assert_equal(true, @controller.facebook_params['in_canvas'])    
  end
  
  def test_facebook_params_convert_expirey_into_time_or_nil
    get :index, example_rails_params_including_fb
    assert_nil(@controller.facebook_params['expires'])
    modified_params = example_rails_params_including_fb
    modified_params['fb_sig_expires'] = modified_params['fb_sig_time']
    setup # reset session and cached params
    get :index, modified_params
    assert_equal("Wed Aug 08 09:51:15 -0600 2007", @controller.facebook_params['expires'].to_s)
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
  
  private
  def example_rails_params_including_fb
    {"fb_sig_time"=>"1186588275.5988", "fb_sig"=>"7371a6400329b229f800a5ecafe03b0a", "action"=>"index", "fb_sig_in_canvas"=>"1", "fb_sig_session_key"=>"c452b5d5d60cbd0a0da82021-744961110", "controller"=>"controller_which_requires_facebook_authentication", "fb_sig_expires"=>"0", "fb_sig_friends"=>"417358,702720,1001170,1530839,3300204,3501584,6217936,9627766,9700907,22701786,33902768,38914148,67400422,135301144,157200364,500103523,500104930,500870819,502149612,502664898,502694695,502852293,502985816,503254091,504510130,504611551,505421674,509229747,511075237,512548373,512830487,517893818,517961878,518890403,523589362,523826914,525812984,531555098,535310228,539339781,541137089,549405288,552706617,564393355,564481279,567640762,568091401,570201702,571469972,573863097,574415114,575543081,578129427,578520568,582262836,582561201,586550659,591631962,592318318,596269347,596663221,597405464,599764847,602995438,606661367,609761260,610544224,620049417,626087078,628803637,632686250,641422291,646763898,649678032,649925863,653288975,654395451,659079771,661794253,665861872,668960554,672481514,675399151,678427115,685772348,686821151,687686894,688506532,689275123,695551670,710631572,710766439,712406081,715741469,718976395,719246649,722747311,725327717,725683968,725831016,727580320,734151780,734595181,737944528,748881410,752244947,763868412,768578853,776596978,789728437,873695441", "fb_sig_added"=>"0", "fb_sig_api_key"=>"b6c9c857ac543ca806f4d3187cd05e09", "fb_sig_user"=>"744961110", "fb_sig_profile_update_time"=>"1180712453"}
  end
  
end
rescue LoadError
  $stderr.puts "Couldn't find action controller.  That's OK.  We'll skip it."
end