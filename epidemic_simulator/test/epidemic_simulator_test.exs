defmodule EpidemicSimulatorTest do
  use ExUnit.Case

  test "can create a population and simulate a virus" do
    EpidemicSimulator.create_population(2, 2)
    EpidemicSimulator.start_virus(:Adult1)
    # cuanto pasa
    assert EpidemicSimulator.amount_of_sick_people() == 3
  end
end
