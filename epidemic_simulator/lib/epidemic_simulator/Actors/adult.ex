defmodule EpidemicSimulator.Adult do
  use GenServer
  import EpidemicSimulator.Person

  def start_link([name, pos, neighbours]) do
    GenServer.start_link(__MODULE__, [name, pos, neighbours], name: name)
  end

  @impl true
  def init([name, pos, neighbours]) do
    contagion_resistance = 0.2
    comorbidities = 0.1

    initial_state =
      initialize_person_with(name, pos, neighbours, contagion_resistance, comorbidities)

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:health_status, _, state) do
    {:reply, state.health_status, state}
  end

  @impl true
  def handle_cast({:infect, virus}, state) do
    new_state = virus_enter_the_body(state, virus)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:stop_simulating, state) do
    new_state = %{state | simulation_running: false}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:start_simulating, state) do
    new_state = %{state | simulation_running: true}

    if new_state.health_status == :sick do
      convalescence_period(state.name, state.virus)
      infect_neighbours(state.neighbours, state.virus)
    end

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:ring, state) do
    Agent.stop(String.to_atom("#{state.name}_timer"))

    new_health_status =
      get_next_health_status(state.health_status, state.virus, state.comorbidities)

    new_state = act_based_on_new_health_status(new_health_status, state)

    {:noreply, new_state}
  end
end
