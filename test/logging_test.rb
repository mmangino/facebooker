require 'facebooker'
require 'rubygems'
require 'flexmock/test_unit'

class LoggingTest < Test::Unit::TestCase
  def setup
    super
    Facebooker.logger = Logger.new(STDERR)
  end  
  def teardown
    Facebooker.logger = nil    
    super
  end
  
  def test_does_not_crash_with_nil_logger
    Facebooker.logger = nil
    Facebooker::Logging.refresh_colorize_logging
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  end

  def test_does_not_crash_outside_rails
    Facebooker::Logging.refresh_colorize_logging
    flexmock(Facebooker.logger, :logger).should_receive(:debug).once.with(String)
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  end

  def test_plain_format
    flexmock(ActiveRecord::Base, :colorize_logging => false)
    Facebooker::Logging.refresh_colorize_logging
    flexmock(Facebooker.logger, :logger).should_receive(:debug).once.with(
        'sample.api.call (0.000000)  param1 = true, param2 = value2')
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  ensure
    Facebooker.logger = nil
  end

  def test_colorized_format
    Facebooker::Logging.class_eval "@@row_even = false"
    flexmock(ActiveRecord::Base, :colorize_logging => true)    
    Facebooker::Logging.refresh_colorize_logging
    flexmock(Facebooker.logger, :logger).should_receive(:debug).once.with(
        "  \e[4;35;1msample.api.call (0.000000)\e[0m   \e[0mparam1 = true, param2 = value2\e[0m")
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  end
  
  def test_colorized_exception
    Facebooker::Logging.class_eval "@@row_even = false"
    flexmock(ActiveRecord::Base, :colorize_logging => true)    
    Facebooker::Logging.refresh_colorize_logging
    flexmock(Facebooker.logger, :logger).should_receive(:debug).once.with(
        "  \e[4;35;1msample.api.call (0.000000)\e[0m   \e[0mRuntimeError: Exception test: param1 = true, param2 = value2\e[0m")
    
    assert_raise RuntimeError do
      Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'}) do
        raise 'Exception test'
      end
    end   
  end  
end
