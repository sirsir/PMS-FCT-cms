require 'test_helper'

class CaptionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:captions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create caption" do
    assert_difference('Caption.count') do
      post :create, :caption => { }
    end

    assert_redirected_to caption_path(assigns(:caption))
  end

  test "should show caption" do
    get :show, :id => captions(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => captions(:one).id
    assert_response :success
  end

  test "should update caption" do
    put :update, :id => captions(:one).id, :caption => { }
    assert_redirected_to caption_path(assigns(:caption))
  end

  test "should destroy caption" do
    assert_difference('Caption.count', -1) do
      delete :destroy, :id => captions(:one).id
    end

    assert_redirected_to captions_path
  end
end
