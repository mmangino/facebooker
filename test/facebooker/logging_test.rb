require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'logger'

class Facebooker::LoggingTest < Test::Unit::TestCase
  def setup
    super
    Facebooker.logger = Logger.new(STDERR)
    Facebooker::Logging.skip_api_logging=false
  end  
  def teardown
    Facebooker.logger = nil    
    super
  end
  
  def test_does_not_crash_with_nil_logger
    Facebooker.logger = nil
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  end

  def test_does_not_crash_outside_rails
    flexmock(Facebooker.logger, :logger).should_receive(:info).once.with(String)
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  end
  
  def test_can_disable_logging
    Facebooker::Logging.skip_api_logging = true
    flexmock(Facebooker::Logging).should_receive(:log_info).never
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true, 'param2' => 'value2'})
  end 
  
  def test_plain_format
    flexmock(Facebooker.logger, :logger).should_receive(:info).once.with(
        'sample.api.call (0) param1 = true')
    Facebooker::Logging.log_fb_api('sample.api.call',
                          {'param1' => true})
  ensure
    Facebooker.logger = nil
  end

end
