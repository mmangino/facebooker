require File.expand_path(File.dirname(__FILE__) + '/test_helper')

tmp = $-w
$-w = nil
require 'action_controller'
require 'action_controller/test_process'
require 'active_record'
$-w = tmp
gem 'rails'
require 'initializer'
require File.dirname(__FILE__)+'/../init'
require 'facebooker/rails/controller'
require 'facebooker/rails/helpers/fb_connect'
require 'facebooker/rails/helpers'
require 'facebooker/rails/publisher'
require 'facebooker/rails/facebook_form_builder'

ActionController::Routing::Routes.draw do |map|
  map.connect '', :controller=>"facebook",:conditions=>{:canvas=>true}
  map.connect '', :controller=>"plain_old_rails"
  map.resources :comments, :controller=>"plain_old_rails"
  map.connect 'require_auth/:action', :controller => "controller_which_requires_facebook_authentication"
  map.connect 'require_install/:action', :controller => "controller_which_requires_application_installation"
  silence_warnings do
    map.connect ':controller/:action/:id', :controller => "plain_old_rails"
  end
end
