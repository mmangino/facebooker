require File.expand_path(File.dirname(__FILE__) + '/../../rails_test_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/facebooker/rails/integration_session')

class Facebooker::Rails::IntegrationSessionTest < Test::Unit::TestCase 

  def test_include_api_key_in_default_request_params
    ENV['FACEBOOK_API_KEY'] = 'a key'
    integration_session = Facebooker::Rails::IntegrationSession.new
    integration_session.reset!
    assert_equal 'a key', integration_session.default_request_params[ :fb_sig_api_key ]
  end

end
