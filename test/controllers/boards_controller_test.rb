require "test_helper"

class BoardsControllerTest < ActionDispatch::IntegrationTest
  test "should get update" do
    get boards_update_url
    assert_response :success
  end
end
