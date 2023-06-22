defmodule AdultTest do
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
    name = :Adult1

    assert {:ok, pid} = GenServer.start_link(EpidemicSimulator.Adult, [name, []])

    assert :healthy == GenServer.call(pid, :health_status)
  end
end
