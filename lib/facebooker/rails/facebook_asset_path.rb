module ActionView
  module Helpers
    module AssetTagHelper
      def compute_public_path_with_facebooker(*args)
        compute_public_path_without_facebooker(*args).gsub(/#{@controller.request.relative_url_root}/,'')
      end
      
      alias_method_chain :compute_public_path, :facebooker
    end
  end
end