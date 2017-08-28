require 'test_helper'

class RolesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create roles" do
    assert_difference('Roles.count') do
      post :create, :roles => { }
    end

    assert_redirected_to roles_path(assigns(:roles))
  end

  test "should show roles" do
    get :show, :id => roles(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => roles(:one).id
    assert_response :success
  end

  test "should update roles" do
    put :update, :id => roles(:one).id, :roles => { }
    assert_redirected_to roles_path(assigns(:roles))
  end

  test "should destroy roles" do
    assert_difference('Roles.count', -1) do
      delete :destroy, :id => roles(:one).id
    end

    assert_redirected_to roles_path
  end
end
