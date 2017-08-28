require 'test_helper'

class FieldTypesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:field_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create field_type" do
    assert_difference('FieldType.count') do
      post :create, :field_type => { }
    end

    assert_redirected_to field_type_path(assigns(:field_type))
  end

  test "should show field_type" do
    get :show, :id => field_types(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => field_types(:one).id
    assert_response :success
  end

  test "should update field_type" do
    put :update, :id => field_types(:one).id, :field_type => { }
    assert_redirected_to field_type_path(assigns(:field_type))
  end

  test "should destroy field_type" do
    assert_difference('FieldType.count', -1) do
      delete :destroy, :id => field_types(:one).id
    end

    assert_redirected_to field_types_path
  end
end
