defmodule VeritaTest do
  use ExUnit.Case
  doctest Verita

  test "greets the world" do
    assert Verita.hello() == :world
  end
end
