defmodule EpidemicSimulatorTest do
  use ExUnit.Case

  test "can create a population and simulate a virus" do
    EpidemicSimulator.create_population(2, 2)
    EpidemicSimulator.simulate_virus(:Adult1)

    assert EpidemicSimulator.amount_of_sick_people() == 3
  end

  test "can create a bigger population" do
    EpidemicSimulator.create_population(10, 10)
    EpidemicSimulator.simulate_virus(:Adult1)

    assert EpidemicSimulator.amount_of_sick_people() == 3
  end
end
