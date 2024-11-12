defmodule ImessagedTest do
  use ExUnit.Case
  doctest Imessaged

  test "greets the world" do
    assert Imessaged.hello() == :world
  end
end
