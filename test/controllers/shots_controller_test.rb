require "test_helper"

class ShotsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get shots_create_url
    assert_response :success
  end
end
