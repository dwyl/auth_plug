defmodule AuthPlugTest do
  use ExUnit.Case
  doctest AuthPlug

  test "greets the world" do
    assert AuthPlug.hello() == :world
  end
end
