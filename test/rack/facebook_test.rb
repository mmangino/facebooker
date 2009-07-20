require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'rack/facebook'
require 'rack/lint'
require 'rack/mock'

class Rack::FacebookTest < Test::Unit::TestCase
  
  def setup
    flexmock(Facebooker).should_receive(:secret_key).and_return('secret')
    flexmock(Facebooker).should_receive(:load_adapter)
    @app = lambda do |env|
      @env = env
      Rack::Response.new().to_a
    end
    @facebook = Rack::Facebook.new(@app)
    @valid_params = {
      :fb_sig_user => '1',
      :fb_sig => 'ignored'
    }
    @page = Proc.new {|options|
      options ||= @valid_params
      app.post "/", :input => params(options)
    }
  end
  
  def params(p)
    p.map{|*args| args.join('=') }.join('&')
  end
  
  def app
    Rack::MockRequest.new(Rack::Lint.new(@facebook))
  end
  
  def test_without_fb_params
    response = app.post("/")
    assert_equal 200, response.status
  end
  
  def test_converts_request_method
    response = @page.call(:fb_sig_request_method => 'GET', :fb_sig => '4d2a700e90b0bcbe54b9e627d2cc1417')
    assert_equal 200, response.status
    assert_equal 'GET', @env['REQUEST_METHOD']
  end
  
  def test_only_sets_request_method_if_provided
    response = @page.call(:fb_sig_user => '1', :fb_sig => '313dd5caed3d0902d83225ff3ae9a950')
    assert_equal 200, response.status
    assert_equal 'POST', @env['REQUEST_METHOD']
  end

  def test_renders_400_with_invalid_signature
    response = @page.call(:fb_sig => 'wrong', :fb_sig_user => 1)
    assert_equal 400, response.status
  end
  
  def test_skips_with_false_condition
    @facebook = Rack::Facebook.new(@app) { false }
    response = @page.call({})
    assert_equal 200, response.status
  end
  
  def test_skips_with_true_condition_without_fb_sig
    @facebook = Rack::Facebook.new(@app) { true }
    response = @page.call(:fb_sig_user => 'ignored')
    assert_equal 200, response.status
  end
  
  def test_verifies_with_true_condition_with_fb_sig
    @facebook = Rack::Facebook.new(@app) { true }
    response = @page.call(:fb_sig => 'wrong', :fb_sig_user => 'ignored')
    assert_equal 400, response.status
  end
end
