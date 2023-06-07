defmodule EpidemicSimulatorTest do
  use ExUnit.Case

  setup do
    # This runs before each test. We are making sure that each child and adult is deleted when the test finishes
    Supervisor.terminate_child(
      EpidemicSimulator.Supervisor,
      EpidemicSimulator.PopulationSupervisor
    )

    Supervisor.restart_child(EpidemicSimulator.Supervisor, EpidemicSimulator.PopulationSupervisor)
    :ok
  end

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

  test "amount of sick and healthy correctly calculated" do
    EpidemicSimulator.create_population(2, 2)
    EpidemicSimulator.simulate_virus(:Adult1)

    #If we don't use the sleep we ask for the amount of sick people before the virus has time to spread
    :timer.sleep(:timer.seconds(1))

    assert EpidemicSimulator.amount_of_sick_people() == 3
    assert EpidemicSimulator.amount_of_healthy_people() == 1
  end

  test "amount of sick and healthy correctly calculated with a bigger population" do
    EpidemicSimulator.create_population(10, 10)
    EpidemicSimulator.simulate_virus(:Adult1)

    :timer.sleep(:timer.seconds(1))

    assert EpidemicSimulator.amount_of_sick_people() == 3
    assert EpidemicSimulator.amount_of_healthy_people() == 17
  end
end
