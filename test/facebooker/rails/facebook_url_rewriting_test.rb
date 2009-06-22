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


  def test_zero_or_false_on_blank
    assert @rewriter.zero_or_false( "" )
  end

  def test_zero_or_false_on_integer_0
    assert @rewriter.zero_or_false( 0 )
  end

  def test_zero_or_false_on_float_0
    assert @rewriter.zero_or_false( 0.0 )
  end

  def test_zero_or_false_on_string_0
    assert @rewriter.zero_or_false( "0" )
  end

  def test_zero_or_false_on_false
    assert @rewriter.zero_or_false( false )
  end

  def test_zero_or_false_on_nil
    assert @rewriter.zero_or_false( nil )
  end

  def test_zero_or_false_on_string_1
    assert !@rewriter.zero_or_false( "1" )
  end

  def test_zero_or_false_on_numeric_1
    assert !@rewriter.zero_or_false( 1 )
  end

  def test_zero_or_false_on_true
    assert !@rewriter.zero_or_false( true )
  end

end
