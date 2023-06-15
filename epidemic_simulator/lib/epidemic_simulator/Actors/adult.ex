defmodule EpidemicSimulator.Adult do
  use GenServer
  import EpidemicSimulator.Person

  def start_link([name, neighbours]) do
    GenServer.start_link(__MODULE__, [name, neighbours], name: name)
  end

  @impl true
  def init([name, neighbours]) do
    contagion_resistance = 0.2

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
    new_state = virus_enter_the_body(state, virus)

    {:noreply, new_state}
  end

  def handle_cast(:stop_simulating, state) do
    new_state = %{state | simulation_running: false}
    {:noreply, new_state}
  end

  def handle_cast(:start_simulating, state) do
    new_state = %{state | simulation_running: true}

    if new_state.health_status == :sick do
      convalescence_period(state.name, state.virus)
      infect_neighbours(state.neighbours, state.virus)
    end

    {:noreply, new_state}
  end

  def handle_cast(:get_sick, state) do
    Agent.stop(String.to_atom("#{state.name}_timer"))
    IO.puts("#{state.name}: I got sick")
    new_state = %{state | health_status: :sick}

    if state.simulation_running do
      convalescence_period(state.name, state.virus)
      infect_neighbours(state.neighbours, state.virus)
    end

    {:noreply, new_state}
  end

  def handle_cast(:finish_convalescence, state) do
    Agent.stop(String.to_atom("#{state.name}_timer"))
    IO.puts("#{state.name}: I'm healthy again (or not)")

    # new_state = %{state | health_status: :healthy}
    {:noreply, state}
  end

end
