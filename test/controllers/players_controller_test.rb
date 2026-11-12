require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  test "shows the name form" do
    get root_path
    assert_response :success
  end

  test "creating a player signs them in" do
    assert_difference "Player.count" do
      post players_path, params: { player: { name: "Dave" } }
    end
    assert_redirected_to games_path
  end

  test "a blank name is rejected" do
    post players_path, params: { player: { name: "" } }
    assert_response :unprocessable_entity
  end
end
