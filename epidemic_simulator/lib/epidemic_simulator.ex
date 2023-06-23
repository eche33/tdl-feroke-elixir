defmodule EpidemicSimulator do
  use GenServer

  defstruct [:population, :population_health_status, :virus, :simulation_start_datetime]

  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  def create_population do
    IO.puts("How many adults do you want to create?")
    adults = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("How many children do you want to create?")
    children = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Creating population with #{adults} adults and #{children} children")
    create_population(adults, children)
  end

  def create_virus do
    IO.puts("Insert the virality:")
    virality = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Insert incubation time (in seconds):")
    incubation_time = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Insert sick time (in seconds):")
    sick_time = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Insert lethality (percentage between 0 and 100):")
    lethality_percentage = IO.gets("") |> String.trim() |> String.to_integer()
    lethality = lethality_percentage / 100

    create_virus(virality, incubation_time, sick_time, lethality)
  end

  def simulate_virus(time) do
    if GenServer.call(@me, :has_virus) do
      raise "You need to create a virus first"
    end

    if GenServer.call(@me, :has_population) do
      raise "You need to create a population first"
    end

    # Ploteo la situación inicial
    GenServer.cast(MedicalCenter, :plot)

    # Inicio la secuencia de ploteo - se puede juntar con situacion inicial
    timer_name = String.to_atom("MedicalCenter_timer")
    timer_period = 1
    EpidemicSimulator.Timer.start_timer(timer_name, MedicalCenter, timer_period)

    GenServer.cast(@me, {:simulate_virus, time})
  end

  def amount_of(health_status) do
    GenServer.call(@me, {:amount_of, health_status})
  end

  def create_population(adults, childs) do
    GenServer.call(@me, [:create_population, adults, childs])
  end

  def create_virus(virality, incubation_time, sick_time, lethality) do
    GenServer.call(@me, [:create_virus, virality, incubation_time, sick_time, lethality])
  end

  @impl true
  def init(:ok) do
    population_health_status = %{:healthy => 0, :sick => 0, :dead => 0, :immune => 0}

    initial_state = %@me{
      population: [],
      population_health_status: population_health_status,
      virus: nil
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call(:has_population, _, state) do
    {:reply, state.population == [], state}
  end

  @impl true
  def handle_call(:has_virus, _, state) do
    {:reply, state.virus == nil, state}
  end

  @impl true
  def handle_call([:create_population, adults, childs], _from, state) do
    childs = create_person_names(:Child, childs)
    adults = create_person_names(:Adult, adults)
    population_names = childs ++ adults

    population = population_names |> assign_random_space_positions |> find_neighbours

    population |> Enum.map(fn person_info -> create_person(person_info) end)

    population_name = population |> Enum.map(fn {nombre, _, _, _} -> nombre end)

    new_state = %{
      state
      | population: population_name,
        population_health_status: %{healthy: length(population_name), sick: 0, dead: 0, immune: 0}
    }

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:amount_of, health_status}, _, state) do
    result = Map.get(state.population_health_status, health_status)
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

    timer_identifier = String.to_atom("#{@me}_timer")
    EpidemicSimulator.Timer.start_timer(timer_identifier, @me, time)

    first_infected_person = Enum.random(state.population)
    GenServer.cast(first_infected_person, {:infect, state.virus})

    new_state = %{
      state
      | simulation_start_datetime: DateTime.utc_now()
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:ring, state) do
    Agent.stop(String.to_atom("#{@me}_timer"))

    Enum.each(state.population, fn person ->
      GenServer.cast(person, :stop_simulating)
    end)

    simulation_time = DateTime.diff(DateTime.utc_now(), state.simulation_start_datetime)

    :timer.sleep(:timer.seconds(state.virus.sick_time + state.virus.incubation_time))

    # Plotea el estado final
    GenServer.cast(MedicalCenter, :plot)

    # Termina el timer - se junta con plot de estado final
    timer_name = "MedicalCenter_timer"
    #timer_name = String.to_atom("MedicalCenter_timer")
    Agent.stop(String.to_atom(timer_name))

    IO.puts("")
    IO.puts("-------------------")
    IO.puts("Simulation finished")
    IO.puts("Simulation time: #{inspect(simulation_time)}")

    {:noreply, state}
  end

  defp assign_random_space_positions(population) do
    random_between = fn (min_value, max_value) -> :rand.uniform() * (max_value - min_value) + min_value end

    population
    |> Enum.map(fn {nombre, tipo} -> {nombre, tipo, {random_between.(0, 5), random_between.(0, 5)}} end)
  end

  defp find_neighbours(population) do
    population |> Enum.map(fn person -> find_closest_persons_to(population, person) end)
  end

  defp find_closest_persons_to(population, a_person) do
    {name, person_type, position} = a_person

    neighbours =
      population
      |> Enum.filter(fn {other_name, _, _} -> other_name != name end)
      |> Enum.map(fn {other_name, other_person_type, other_position} ->
        {other_name, other_person_type, other_position, distance({name, position}, {other_name, other_position})}
      end)
      |> Enum.sort_by(fn {_, _, _, distance} -> distance end)
      |> Enum.filter(fn {_, _, _, distance} -> distance < 1 end)
      |> Enum.map(fn {other_name, _, _, _} -> other_name end)

    {name, person_type, position, neighbours}
  end

  defp distance({_, {x1, y1}}, {_, {x2, y2}}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  defp create_person_names(person_type, amount) do
    Enum.map(1..amount, fn i ->
      {String.to_atom("#{person_type}#{i}"), person_type}
    end)
  end

  defp create_person(person_information) do
    {name, person_type, pos, neighbours} = person_information

    actor =
      cond do
        person_type == :Child -> EpidemicSimulator.Child
        person_type == :Adult -> EpidemicSimulator.Adult
      end

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        EpidemicSimulator.PopulationSupervisor,
        {actor, [name, pos, neighbours]}
      )
  end
end
