defmodule EpidemicSimulator do
  use GenServer

  defstruct [:population, :population_health_status, :virus, :simulation_start_datetime]

  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  def create_population(adults, childs) do
    GenServer.call(@me, [:create_population, adults, childs])
  end

  def create_virus(virality, incubation_time, sick_time, lethality) do
    GenServer.call(@me, [:create_virus, virality, incubation_time, sick_time, lethality])
  end

  def simulate_virus(time) do
    population = GenServer.call(@me, :population)
    virus = GenServer.call(@me, :virus)

    if virus == nil do
      raise "You need to create a virus first"
    end

    if population == [] do
      raise "You need to create a population first"
    end

    GenServer.cast(@me, {:simulate_virus, time})
  end

  def amount_of_sick_people() do
    GenServer.call(@me, :amount_of_sick_people)
  end

  def amount_of_healthy_people() do
    GenServer.call(@me, :amount_of_healthy_people)
  end

  def amount_of_dead_people() do
    GenServer.call(@me, :amount_of_dead_people)
  end

  def amount_of_immune_people() do
    GenServer.call(@me, :amount_of_immune_people)
  end

  def stop_simulation() do
    GenServer.cast(@me, :stop_simulation)
  end

  # private

  defp create_child(name, neighbours) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        EpidemicSimulator.PopulationSupervisor,
        {EpidemicSimulator.Child, [name, neighbours]}
      )
  end

  defp create_adult(name, neighbours) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        EpidemicSimulator.PopulationSupervisor,
        {EpidemicSimulator.Adult, [name, neighbours]}
      )
  end

  @impl true
  def init(:ok) do
    initial_state = %@me{population: [], population_health_status: %{}, virus: nil}

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:population, _, state) do
    {:reply, state.population, state}
  end

  @impl true
  def handle_call(:virus, _, state) do
    {:reply, state.virus, state}
  end

  @impl true
  def handle_call([:create_population, adults, children], _from, state) do
    childs =
      Enum.map(1..children, fn i ->
        String.to_atom("Child#{i}")
      end)

    adults =
      Enum.map(1..adults, fn i ->
        String.to_atom("Adult#{i}")
      end)

    population = childs ++ adults

    IO.puts("Population: #{inspect(population)}")

    # For each child, create a child actor
    Enum.each(childs, fn child ->
      create_child(child, population)
    end)

    # For each adult, create a adult actor
    Enum.each(adults, fn adult ->
      create_adult(adult, population)
    end)

    new_state = %{
      state
      | population: population,
        population_health_status: %{:healthy => length(population)}
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:amount_of_sick_people, _, state) do
    result =
      Enum.count(state.population, fn person ->
        GenServer.call(person, :is_sick)
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:amount_of_healthy_people, _, state) do
    result =
      Enum.count(state.population, fn person ->
        GenServer.call(person, :is_healthy)
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:amount_of_dead_people, _, state) do
    result =
      Enum.count(state.population, fn person ->
        GenServer.call(person, :is_dead)
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:amount_of_immune_people, _, state) do
    result =
      Enum.count(state.population, fn person ->
        GenServer.call(person, :is_immune)
      end)

    {:reply, result, state}
  end

  @impl true
  def handle_call(:simulation_running?, _from, state) do
    sick_people = state.population_health_status[:sick]

    response = sick_people != length(state.population)

    {:reply, response, state}
  end

  @impl true
  def handle_call([:create_virus, virality, incubation_time, sick_time, lethality], _from, state) do
    virus = %EpidemicSimulator.Structs.VirusInformation{
      virality: virality,
      incubation_time: incubation_time,
      lethality: lethality,
      sick_time: sick_time
    }

    new_state = %{
      state
      | virus: virus
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:simulate_virus, time}, state) do
    Enum.each(state.population, fn person ->
      GenServer.cast(person, :start_simulating)
    end)

    timer_identifier =  String.to_atom("#{@me}_timer")
    EpidemicSimulator.Timer.start_timer(timer_identifier, @me, time, :stop_simulation)

    first_infected_person = Enum.random(state.population)
    GenServer.cast(first_infected_person, {:infect, state.virus})

    new_state = %{
      state
      | simulation_start_datetime: DateTime.utc_now()
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:stop_simulation, state) do
    Agent.stop(String.to_atom("#{@me}_timer"))

    Enum.each(state.population, fn person ->
      GenServer.cast(person, :stop_simulating)
    end)

    simulation_time = DateTime.diff(DateTime.utc_now(), state.simulation_start_datetime)
    IO.puts("Simulation time: #{inspect(simulation_time)}")

    {:noreply, state}
  end
end
