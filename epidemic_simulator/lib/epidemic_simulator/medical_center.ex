defmodule EpidemicSimulator.MedicalCenter do
  use GenServer

  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  def plot(citizens, simulation_step) do
    census_data =
      citizens
      |> Enum.map(fn {key, {x, y, health_status}} -> {x, y, key, "#{health_status}"} end)

    EpidemicSimulator.PopulationGraphPlotter.generate_graph_plot_for(census_data, simulation_step)
  end

  @impl true
  def init(:ok) do
    initial_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: %{},
      step: 0
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:census, name, position, health_status}, state) do
    {x, y} = position

    updated_citizens = Map.put(state.citizens, name, {x, y, health_status})

    new_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: updated_citizens,
      step: state.step
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:plot, state) do
    plot(state.citizens, state.step)

    new_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: state.citizens,
      step: state.step + 1
    }

    {:noreply, new_state}
  end
end
