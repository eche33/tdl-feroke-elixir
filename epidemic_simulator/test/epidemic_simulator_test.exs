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

  test "can't simulate without a created population" do
    assert_raise RuntimeError, fn ->
      EpidemicSimulator.simulate_virus(:Adult1)
    end
  end

  test "can't simulate without a created virus" do
    EpidemicSimulator.create_population(2, 2)

    assert_raise RuntimeError, fn ->
      EpidemicSimulator.simulate_virus(:Adult1)
    end
  end

  test "create population successfully" do
    EpidemicSimulator.create_population(2, 2)

    assert EpidemicSimulator.amount_of(:sick) == 0
    assert EpidemicSimulator.amount_of(:healthy) == 4
  end

  # Commented this tests since if it's a simulation we can't really predict what's going to happen
  # test "amount of sick and healthy correctly calculated" do
  #   EpidemicSimulator.create_population(2, 2)
  #   EpidemicSimulator.create_virus(3)
  #   EpidemicSimulator.simulate_virus(:Adult1)

  #   # If we don't use the sleep we ask for the amount of sick people before the virus has time to spread
  #   :timer.sleep(:timer.seconds(2))
  #   EpidemicSimulator.stop_simulation()

  #   assert EpidemicSimulator.amount_of_sick_people() == 4
  #   assert EpidemicSimulator.amount_of_healthy_people() == 0
  # end

  # test "amount of sick and healthy correctly calculated with a bigger population" do
  #   EpidemicSimulator.create_population(10, 10)
  #   EpidemicSimulator.create_virus(2)
  #   EpidemicSimulator.simulate_virus(:Adult1)

  #   :timer.sleep(:timer.seconds(2))
  #   EpidemicSimulator.stop_simulation()

  #   assert EpidemicSimulator.amount_of_sick_people() == 20
  #   assert EpidemicSimulator.amount_of_healthy_people() == 0
  # end
end
