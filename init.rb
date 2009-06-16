# Added support to the Facebooker.yml file for switching to the new profile design..
# Config parsing needs to happen before files are required.
facebook_config = "#{RAILS_ROOT}/config/facebooker.yml"

require 'facebooker'
FACEBOOKER = Facebooker.load_configuration(facebook_config)

# enable logger before including everything else, in case we ever want to log initialization
Facebooker.logger = RAILS_DEFAULT_LOGGER if Object.const_defined? :RAILS_DEFAULT_LOGGER

require 'net/http_multipart_post'
if defined? Rails
  require 'facebooker/rails/backwards_compatible_param_checks'
  require 'facebooker/rails/controller'
  require 'facebooker/rails/facebook_url_rewriting'
  require 'facebooker/rails/facebook_session_handling' if Rails.version < '2.3'
  require 'facebooker/rails/facebook_request_fix' if Rails.version < '2.3'
  require 'facebooker/rails/facebook_request_fix_2-3' if Rails.version >= '2.3'
  require 'facebooker/rails/routing'
  require 'facebooker/rails/facebook_pretty_errors' rescue nil
  require 'facebooker/rails/facebook_url_helper'
  require 'facebooker/rails/extensions/rack_setup' if Rails.version > '2.3'
  require 'facebooker/rails/extensions/action_controller'
  #require 'facebooker/rails/extensions/action_view'
  require 'facebooker/rails/extensions/routing'
end
