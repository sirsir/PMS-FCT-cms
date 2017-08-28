require 'test_helper'

class FieldsReportsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fields_reports)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fields_report" do
    assert_difference('FieldsReport.count') do
      post :create, :fields_report => { }
    end

    assert_redirected_to fields_report_path(assigns(:fields_report))
  end

  test "should show fields_report" do
    get :show, :id => fields_reports(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => fields_reports(:one).id
    assert_response :success
  end

  test "should update fields_report" do
    put :update, :id => fields_reports(:one).id, :fields_report => { }
    assert_redirected_to fields_report_path(assigns(:fields_report))
  end

  test "should destroy fields_report" do
    assert_difference('FieldsReport.count', -1) do
      delete :destroy, :id => fields_reports(:one).id
    end

    assert_redirected_to fields_reports_path
  end
end
