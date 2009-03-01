require 'action_controller/integration'

class Facebooker::Rails::IntegrationSession < ActionController::Integration::Session
  include Facebooker::Rails::TestHelpers
  attr_accessor :default_request_params, :canvas
  
  def process(method, path, parameters = nil, headers = nil)
    if canvas
      parameters = facebook_params(@default_request_params.merge(parameters || {}))
    end
    super method, path, parameters, headers
  end
  
  def reset!
    self.default_request_params = {:fb_sig_in_canvas => '1'}.with_indifferent_access
    self.canvas = true
    super
  end
  
  def get_with_canvas(path, parameters = nil, headers = nil)
    if canvas
      post path, (parameters || {}).merge('fb_sig_request_method' => 'GET'), headers
    else
      get_without_canvas path, parameters, headers
    end
  end
  alias_method_chain :get, :canvas
  
  %w(put delete).each do |method|
    define_method "#{method}_with_canvas" do |*args|
      if canvas
        path, parameters, headers = *args
        post path, (parameters || {}).merge('_method' => method.upcase), headers
      else
        send "#{method}_without_canvas", *args
      end
    end
    alias_method_chain method, :canvas
  end
end
