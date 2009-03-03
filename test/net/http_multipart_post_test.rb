require File.expand_path(File.dirname(__FILE__) + '/../test_helper')
require 'net/http_multipart_post'

class HttpMulitpartPostTest < Test::Unit::TestCase
  def setup
    super
  end
  
  def fixture(string)
    File.open(File.dirname(__FILE__) + "/../fixtures/#{string}.txt").read
  end
  
  def test_multipart_post_with_only_parameters
    params = add_sample_facebook_params({})
    post = Net::HTTP::MultipartPost.new("uri", params)
    assert_equal fixture("multipart_post_body_with_only_parameters"), post.send(:body)
  end
  
  def test_multipart_post_with_a_single_file
    params = add_sample_facebook_params({})
    params[:file] = Net::HTTP::MultipartPostFile.new
    params[:file].filename = "somefilename.jpg"
    params[:file].content_type = "image/jpg"
    params[:file].data = "[Raw file data here]"
    post = Net::HTTP::MultipartPost.new("uri", params)
    assert_equal fixture("multipart_post_body_with_single_file"), post.send(:body)
  end
  
  def test_multipart_post_with_a_single_file_parameter_that_has_nil_key
    params = add_sample_facebook_params({})
    params[nil] = Net::HTTP::MultipartPostFile.new("somefilename.jpg", "image/jpg", "[Raw file data here]")
    post = Net::HTTP::MultipartPost.new("uri", params)
    assert_equal fixture("multipart_post_body_with_single_file_that_has_nil_key"), post.send(:body)
  end
  
  def test_multipart_post_should_have_correct_content_type
    post = Net::HTTP::MultipartPost.new("uri", {})
    assert post.send(:content_type) =~ /multipart\/form-data; boundary=/
  end
  
  def add_sample_facebook_params(hash)
    hash[:method] = "facebook.photos.upload"
    hash[:v] = "1.0"
    hash[:api_key] = "77a52842357422fadd912a2600e6e53c"
    hash[:session_key] = "489727d0ab2efc6e8003018c-i2LLkn8BDb2s."
    hash[:call_id] = "1172623588.023010"
    hash[:caption] = "Under the sunset"
    hash[:aid] = "940915667462717"
    hash[:sig] = "dfa724b8a5cd97d9df4baf2b60d3484c"
    hash
  end
end