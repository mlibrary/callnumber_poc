require "test_helper"

class CallnumberControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get callnumber_first_url
    assert_response :success
  end

  test "should get next" do
    get callnumber_next_url
    assert_response :success
  end

  test "should get last" do
    get callnumber_last_url
    assert_response :success
  end
end
