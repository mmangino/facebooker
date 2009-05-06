require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class Facebooker::BatchRequestTest < Test::Unit::TestCase
  
  def setup
    @proc_called=false
    @batch_request=Facebooker::BatchRequest.new({:params=>true},nil)
  end
  
  def test_can_set_result
    
  end
  
  def test_can_set_result_with_proc_and_have_proc_called
    p=Proc.new {@proc_called=true}
    
    @batch_request=Facebooker::BatchRequest.new({:params=>true},p)
    @batch_request.result="Mike"
    assert @proc_called
  end
  def test_can_set_result_with_proc_and_use_proc_result
    p=Proc.new {@proc_called=true}
    
    @batch_request=Facebooker::BatchRequest.new({:params=>true},p)
    @batch_request.result="Mike"
    assert @batch_request
  end
  
  def test_proxies_methods
    @batch_request.result="Mike"
    assert @batch_request == "Mike"
  end
  
  def test_threequal_works
    @batch_request.result="Mike"
    assert @batch_request === String
  end
  
  def test_can_set_exception_and_check_it
    @batch_request.exception_raised=ArgumentError.new
    assert_raises(ArgumentError) {
      @batch_request.exception_raised?
    }
  end
  def test_can_set_exception_and_have_it_raised_on_access
    @batch_request.exception_raised=ArgumentError.new
    assert_raises(ArgumentError) {
      @batch_request == true
    }
  end
  def test_exception_raised_false_when_no_exception
    @batch_request.result="Mike"
    assert ! @batch_request.exception_raised?
  end
  
  # def test_case_works
  #   @batch_request.result="Mike"
  #   case @batch_request
  #     when String
  #     else 
  #       fail("case failed")
  #   end
  #   
  # end
  
  def test_calling_method_without_result_raises_exception
    assert_raises(Facebooker::BatchRequest::UnexecutedRequest) {
      @batch_request.to_s
    }
  end
  
  def test_respond_to
    @batch_request.result=[]
    assert @batch_request.respond_to?(:empty?)
  end
  
  def test_calling_method_after_exception_re_raises_exception
    @batch_request.result="String"
    assert_raises(NoMethodError) {
      @batch_request.fake
    }
  end
end