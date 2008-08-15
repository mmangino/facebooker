require 'test_helper'
require File.dirname(__FILE__)+'/../../vendor/plugins/facebooker/lib/facebooker/rails/test_helpers.rb'

class <%= controller_class_name %>ControllerTest < ActionController::TestCase
  include Facebooker::Rails::TestHelpers
  def test_should_get_index_for_facebook
    facebook_get :index
    assert_response :success
    assert_not_nil assigns(:<%= table_name %>)
  end

  def test_should_get_new_for_facebook
    facebook_get :new
    assert_response :success
  end

  def test_should_create_<%= file_name %>_for_facebook
    assert_difference('<%= class_name %>.count') do
      facebook_post :create, :<%= file_name %> => { }
    end

    assert_facebook_redirect_to <%= file_name %>_path(assigns(:<%= file_name %>))
  end

  def test_should_show_<%= file_name %>_for_facebook
    facebook_get :show, :id => <%= table_name %>(:one).id
    assert_response :success
  end

  def test_should_get_edit_for_facebook
    facebook_get :edit, :id => <%= table_name %>(:one).id
    assert_response :success
  end

  def test_should_update_<%= file_name %>_for_facebook
    facebook_put :update, :id => <%= table_name %>(:one).id, :<%= file_name %> => { }
    assert_facebook_redirect_to <%= file_name %>_path(assigns(:<%= file_name %>))
  end

  def test_should_destroy_<%= file_name %>_for_facebook
    assert_difference('<%= class_name %>.count', -1) do
      facebook_delete :destroy, :id => <%= table_name %>(:one).id
    end

    assert_facebook_redirect_to <%= table_name %>_path
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:<%= table_name %>)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_<%= file_name %>
    assert_difference('<%= class_name %>.count') do
      post :create, :<%= file_name %> => { }
    end

    assert_redirected_to <%= file_name %>_path(assigns(:<%= file_name %>))
  end

  def test_should_show_<%= file_name %>
    get :show, :id => <%= table_name %>(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => <%= table_name %>(:one).id
    assert_response :success
  end

  def test_should_update_<%= file_name %>
    put :update, :id => <%= table_name %>(:one).id, :<%= file_name %> => { }
    assert_redirected_to <%= file_name %>_path(assigns(:<%= file_name %>))
  end

  def test_should_destroy_<%= file_name %>
    assert_difference('<%= class_name %>.count', -1) do
      delete :destroy, :id => <%= table_name %>(:one).id
    end

    assert_redirected_to <%= table_name %>_path
  end
end
