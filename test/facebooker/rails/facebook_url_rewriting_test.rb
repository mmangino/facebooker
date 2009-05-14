require File.expand_path(File.dirname(__FILE__) + '/../../rails_test_helper')

class Facebooker::Rails::FacebookUrlRewritingTest < Test::Unit::TestCase

  def setup
    @request = ActionController::TestRequest.new
    @params = {}
    @rewriter = ActionController::UrlRewriter.new(@request, @params)
  end

  def test_one_or_true_on_string_1
    assert @rewriter.one_or_true( "1" )
  end
  
  def test_one_or_true_on_string_0
    assert !@rewriter.one_or_true( "0" )
  end

  def test_one_or_true_on_integer_1
    assert @rewriter.one_or_true( 1 )
  end

  def test_one_or_true_on_float_1
    assert @rewriter.one_or_true( 1.0 )
  end
  
  def test_one_or_true_on_true
    assert @rewriter.one_or_true( true )
  end

  def test_one_or_true_on_false
    assert !@rewriter.one_or_true( false )
  end

  def test_one_or_true_on_nil
    assert !@rewriter.one_or_true( nil )
  end

end
