defmodule EpidemicSimulator.Adult do
  use GenServer
  import EpidemicSimulator.Person

  def start_link([name, neighbours]) do
    GenServer.start_link(__MODULE__, [name, neighbours], name: name)
  end

  @impl true
  def init([name, neighbours]) do
    contagion_resistance = 0.2
    comorbidities = 0.1

    initial_state = initialize_person_with(name, neighbours, contagion_resistance, comorbidities)

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
  def handle_call(:is_dead, _, state) do
    {:reply, state.health_status == :dead, state}
  end

  @impl true
  def handle_call(:is_immune, _, state) do
    {:reply, state.health_status == :immune, state}
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

  # def handle_cast(:get_sick, state) do
  #   Agent.stop(String.to_atom("#{state.name}_timer"))
  #   IO.puts("#{state.name}: I got sick")
  #   new_state = %{state | health_status: :sick}

  #   if state.simulation_running do
  #     convalescence_period(state.name, state.virus)
  #     infect_neighbours(state.neighbours, state.virus)
  #   end

  #   {:noreply, new_state}
  # end

  # def handle_cast(:finish_convalescence, state) do
  #   Agent.stop(String.to_atom("#{state.name}_timer"))

  #   new_health_status = heal_or_die(state.virus, state.comorbidities)

  #   if new_health_status == :immune do
  #     IO.puts("#{state.name}: I'm immune now!")
  #   else
  #     IO.puts("#{state.name}: I died :(")
  #   end

  #   new_state = %{state | health_status: new_health_status}

  #   {:noreply, new_state}
  # end

  def handle_cast(:ring, state) do
    Agent.stop(String.to_atom("#{state.name}_timer"))

    new_health_status = get_next_health_status(state.health_status, state.virus, state.comorbidities)

    new_state = case new_health_status do
                  :sick ->
                    IO.puts("#{state.name}: I got sick")
                    if state.simulation_running do
                      convalescence_period(state.name, state.virus)
                      infect_neighbours(state.neighbours, state.virus)
                    end
                    %{state | health_status: :sick}

                  :immune ->
                    IO.puts("#{state.name}: I'm immune now!")
                    %{state | health_status: :immune}

                  :dead ->
                    IO.puts("#{state.name}: I died :(")
                    %{state | health_status: :dead}
                end

    {:noreply, new_state}
  end

end
