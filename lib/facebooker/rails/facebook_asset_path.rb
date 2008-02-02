# module ActionView
#   module Helpers
#     module AssetTagHelper
#       def compute_public_path_with_facebooker(*args)
#         public_path=compute_public_path_without_facebooker(*args)
#         if public_path.starts_with?(ActionController::Base.asset_host)
#           str=ActionController::Base.asset_host
#           str += "/" unless str.ends_with?("/")
#           public_path.gsub(/#{Regexp.escape(ActionController::Base.asset_host)}#{@controller.request.relative_url_root}\//,str)
#         else
#           public_path
#         end
#       end
#       
#       alias_method_chain :compute_public_path, :facebooker
#     end
#   end
# end