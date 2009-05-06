require 'digest/md5'
require 'facebooker/service'

module Facebooker
  # A mock service that reads the Facebook response from fixtures
  # Adapted from http://gist.github.com/44344
  #
  #   Facebooker::MockService.fixture_path = 'path/to/dir'
  #   Facebooker::Session.current = Facebooker::MockSession.create
  #
  class MockService < Service
    class << self
      attr_accessor :fixture_path
    end

    def read_fixture(method, filename, original = nil)
      path = fixture_path(method, filename)
      File.read path
    rescue Errno::ENAMETOOLONG
      read_fixture(method, hash_fixture_name(filename), filename)
    rescue Errno::ENOENT => e
      if File.exists?(fixture_path(method, 'default'))
        File.read fixture_path(method, 'default')
      else
        e.message << "\n(Non-hashed path is #{original})" if original
        e.message << "\nFacebook API Reference: http://wiki.developers.facebook.com/index.php/#{method.sub(/^facebook\./, '')}#Example_Return_XML"
        raise e
      end
    end

    def post(params)
      method = params.delete(:method)
      params.delete_if {|k,_| [:v, :api_key, :call_id, :sig].include?(k) }
      Parser.parse(method, read_fixture(method, fixture_name(params)))
    end

  private
    def fixture_path(method, filename)
      File.join(self.class.fixture_path, method, "#{filename}.xml")
    end

    def hash_fixture_name(filename)
      Digest::MD5.hexdigest(filename)
    end

    def fixture_name(params)
      params.map {|*args| args.join('=') }.sort.join('&')
    end
  end
end