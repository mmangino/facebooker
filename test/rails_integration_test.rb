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
end
rescue LoadError
  $stderr.puts "Couldn't find action controller.  That's OK.  We'll skip it."
end