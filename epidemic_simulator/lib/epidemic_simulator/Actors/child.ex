defmodule EpidemicSimulator.Child do
  use GenServer
  import EpidemicSimulator.Person

  def start_link([name, neighbours]) do
    GenServer.start_link(__MODULE__, [name, neighbours], name: name)
  end

  @impl true
  def init([name, neighbours]) do
    contagion_resistance = 0.1
    initial_state = initialize_person_with(name, neighbours, contagion_resistance)

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:is_sick, _, state) do
    {:reply, state.health_status == :sick, state}
  end

  @impl true
  def handle_call(:is_healthy, _, state) do
    {:reply, state.health_status == :healthy, state}
  end

  @impl true
  def handle_cast({:infect, virus}, state) do
    new_health_status = affect_body_with_virus(state, virus)

    new_state_with_virus = %{state | health_status: new_health_status, virus: virus}
    {:noreply, new_state_with_virus}
  end

  def handle_cast(:stop_simulating, state) do
    new_state = %{state | simulation_running: false}
    {:noreply, new_state}
  end

  def handle_cast(:start_simulating, state) do
    new_state = %{state | simulation_running: true}

    if new_state.health_status == :sick do
      :timer.sleep(:timer.seconds(1))
      infect_neighbours(state.neighbours, state.virus)
    end

    {:noreply, new_state}
  end

  def handle_cast(:ring, state) do
    Agent.stop(String.to_atom("#{state.name}_timer"))

    {:noreply, state}
  end
end
