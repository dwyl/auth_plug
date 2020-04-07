defmodule AuthPlugTest do
  use ExUnit.Case
  use Plug.Test
  doctest AuthPlug

  test "greets the world" do
    assert AuthPlug.hello() == :world
  end
end
