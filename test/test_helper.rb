require 'test/unit'
require 'rubygems'

begin
  require 'nokogiri'
rescue LoadError
  # Should work without nokogiri
end

begin
  require 'multi_rails_init'
rescue LoadError
  # multi rails not installed, test against newest supported version of Rails
  gem 'rails', '2.2.2'
end
require 'activesupport'
require 'flexmock/test_unit'
require 'mocha'

$: << File.join(File.dirname(__FILE__), '..', 'lib')

rails_root = File.join(File.dirname(__FILE__),'..','..')
if defined? RAILS_ROOT
  RAILS_ROOT.replace(rails_root)
else
  RAILS_ROOT = rails_root
end

require 'facebooker'
require 'facebooker/rails/test_helpers'

class Test::Unit::TestCase

  include Facebooker::Rails::TestHelpers unless self.included_modules.include?( Facebooker::Rails::TestHelpers )

  private

  def expect_http_posts_with_responses(*responses_xml)
    mock_http = establish_session
    responses_xml.each do |xml_string|
      mock_http.should_receive(:post_form).and_return(xml_string).once.ordered(:posts)
    end
  end

  def establish_session(session = @session)
    mock = flexmock(Net::HTTP).should_receive(:post_form).and_return(example_auth_token_xml).once.ordered(:posts)
    mock.should_receive(:post_form).and_return(example_get_session_xml).once.ordered(:posts)
    session.secure!
    mock
  end

  def example_auth_token_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <auth_createToken_response xmlns="http://api.facebook.com/1.0/" 
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
        xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
        3e4a22bb2f5ed75114b0fc9995ea85f1
        </auth_createToken_response>    
    XML
  end

  def example_get_session_xml
    <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <auth_getSession_response xmlns="http://api.facebook.com/1.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd">
      <session_key>5f34e11bfb97c762e439e6a5-8055</session_key>
      <uid>8055</uid>
      <expires>1173309298</expires>
      <secret>ohairoflamao12345</secret>
    </auth_getSession_response>    
    XML
  end  
end
