require File.expand_path(File.dirname(__FILE__) + '/../../rails_test_helper')
require 'facebooker/rails/facebook_request_fix_2-3' if Rails.version >= '2.3'
class Facebooker::Rails::FacebookRequestFix23Test < Test::Unit::TestCase

  def setup
    ENV['FACEBOOK_API_KEY'] = '1234567'
    ENV['FACEBOOK_SECRET_KEY'] = '7654321'
    if Rails.version < '2.3'      
      @request = ActionController::TestRequest.new({"fb_sig_is_ajax"=>"1"}, {}, nil)
      
    else
      @request = ActionController::TestRequest.new
      @request.query_parameters[:fb_sig_is_ajax] = "1"
    end
  end

  def test_xhr_when_is_ajax
    assert @request.xhr?
  end

  def test_xml_http_request_when_is_ajax
    assert @request.xml_http_request?
  end

end
