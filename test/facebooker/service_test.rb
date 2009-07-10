require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'active_support'
# make sure the class exists
class ::Facebooker::Service::CurlService < Facebooker::Service::BaseService
end

class ::Facebooker::Service::TyphoeusMultiService
  def process
  end
end

class Facebooker::ServiceTest < Test::Unit::TestCase
  
  def test_should_use_the_curl_service
      Facebooker.use_curl = true
      Facebooker::Service.active_service= nil
      assert(Facebooker::Service::CurlService === Facebooker::Service.active_service)
  ensure 
    Facebooker::Service.active_service= nil
  end
  
  def test_should_allow_changing_the_service_in_a_block
    Facebooker::Service.with_service("MyService") do
      assert_equal(Facebooker::Service.active_service,"MyService")
    end
    
  end
  
  def test_should_restore_the_original_service_even_with_an_exception
    original_service = Facebooker::Service.active_service
    begin
      Facebooker::Service.with_service("MyService") do
        raise "This is a test"
      end
      fail("Should have raised")
    rescue
    end
    assert_equal(original_service,Facebooker::Service.active_service)
  end
  
  def test_should_allow_using_the_async_service
    Facebooker::Service.with_async do
      assert(Facebooker::Service::TyphoeusMultiService === Facebooker::Service.active_service)
      @called = true
    end
    assert @called
  end
  
  def test_should_call_process_at_the_end_of_the_block
    Facebooker::Service.with_async do
      Facebooker::Service.active_service.expects(:process)
      @called = true
    end
    assert @called
    
  end
  
end