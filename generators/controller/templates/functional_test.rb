require 'test_helper'
require File.dirname(__FILE__)+'/../../vendor/plugins/facebooker/lib/facebooker/rails/test_helpers.rb'

class <%= class_name %>ControllerTest < ActionController::TestCase
  include Facebooker::Rails::TestHelpers

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
