require 'test_helper'

class FieldFiltersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:field_filters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create field_filter" do
    assert_difference('FieldFilter.count') do
      post :create, :field_filter => { }
    end

    assert_redirected_to field_filter_path(assigns(:field_filter))
  end

  test "should show field_filter" do
    get :show, :id => field_filters(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => field_filters(:one).id
    assert_response :success
  end

  test "should update field_filter" do
    put :update, :id => field_filters(:one).id, :field_filter => { }
    assert_redirected_to field_filter_path(assigns(:field_filter))
  end

  test "should destroy field_filter" do
    assert_difference('FieldFilter.count', -1) do
      delete :destroy, :id => field_filters(:one).id
    end

    assert_redirected_to field_filters_path
  end
end
