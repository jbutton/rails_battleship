require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get games_index_url
    assert_response :success
  end

  test "should get show" do
    get games_show_url
    assert_response :success
  end

  test "should get join" do
    get games_join_url
    assert_response :success
  end

  test "should get fire" do
    get games_fire_url
    assert_response :success
  end
end
