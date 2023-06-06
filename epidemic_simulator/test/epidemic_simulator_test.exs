defmodule EpidemicSimulatorTest do
  use ExUnit.Case
  doctest EpidemicSimulator

  test "greets the world" do
    assert EpidemicSimulator.hello() == :world
  end
end
