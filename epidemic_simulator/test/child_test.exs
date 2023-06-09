defmodule ChildTest do
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

  test "adult created successfully with initial healthy state" do
    name = :Child1

    assert {:ok, pid} = GenServer.start_link(EpidemicSimulator.Child, [name, []])

    assert GenServer.call(pid, :is_healthy)
  end
end
