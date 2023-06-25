defmodule EpidemicSimulator.MedicalCenter do
  use GenServer

  @me __MODULE__
  @timer_name :MedicalCenter_timer
  @timer_period 1

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  def plot(citizens, simulation_step) do
    census_data =
      citizens
      |> Enum.map(fn {key, {x, y, health_status}} -> {x, y, key, "#{health_status}"} end)

    EpidemicSimulator.PopulationGraphPlotter.generate_graph_plot_for(census_data, simulation_step)
  end

  defp plot_and_increment_step(state) do
    plot(state.citizens, state.step)

    next_step = state.step + 1

    %{state | step: next_step}
  end

  @impl true
  def init(:ok) do
    initial_state = %EpidemicSimulator.Structs.MedicalCenterInformation{
      citizens: %{},
      step: 0,
      simulation_running: true
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:census, name, position, health_status}, state) do
    {x, y} = position

    updated_citizens = Map.put(state.citizens, name, {x, y, health_status})

    new_state = %{state | citizens: updated_citizens}

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:plot, state) do
    new_state = plot_and_increment_step(state)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:ring, state) do
    Agent.stop(@timer_name)

    new_state = plot_and_increment_step(state)

    if state.simulation_running do
      EpidemicSimulator.Timer.start_timer(@timer_name, MedicalCenter, @timer_period)
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:start_census, state) do
    new_state = plot_and_increment_step(state)

    EpidemicSimulator.Timer.start_timer(@timer_name, MedicalCenter, @timer_period)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:stop_census, state) do
    new_state = %{state | simulation_running: false}

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:population_health_status, _from, state) do
    population_health_status =
      state.citizens
      |> Map.values()
      |> Enum.map(fn {_, _, health_status} -> health_status end)
      |> Enum.group_by(fn health_status -> health_status end)
      |> Enum.map(fn {health_status, list} -> {health_status, length(list)} end)
      |> Enum.into(%{})

    {:reply, population_health_status, state}

  end

end
