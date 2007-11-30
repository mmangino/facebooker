module Facebooker
  module Rails
    module TestHelpers
      def assert_fb_redirect_to(url)
        assert_equal "fb:redirect", response_from_page_or_rjs.children.first.name
        assert_equal url, response_from_page_or_rjs.children.first.attributes['url']    
      end
    end
  end
end
        