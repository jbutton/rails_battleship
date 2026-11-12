require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not Player.new(name: "").valid?
  end

  test "limits name length" do
    assert_not Player.new(name: "x" * 51).valid?
  end

  test "defaults to idle" do
    assert Player.new(name: "Dave").idle?
  end
end
