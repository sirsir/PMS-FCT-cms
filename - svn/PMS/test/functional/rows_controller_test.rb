require 'test_helper'

class RowsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:rows)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create row" do
    assert_difference('Row.count') do
      post :create, :row => { }
    end

    assert_redirected_to row_path(assigns(:row))
  end

  test "should show row" do
    get :show, :id => rows(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => rows(:one).id
    assert_response :success
  end

  test "should update row" do
    put :update, :id => rows(:one).id, :row => { }
    assert_redirected_to row_path(assigns(:row))
  end

  test "should destroy row" do
    assert_difference('Row.count', -1) do
      delete :destroy, :id => rows(:one).id
    end

    assert_redirected_to rows_path
  end
end
