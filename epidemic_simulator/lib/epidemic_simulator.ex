defmodule EpidemicSimulator do
  use GenServer

  defstruct [:population, :population_health_status, :virus, :simulation_start_datetime]

  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  def create_persons(my_atom, n) do
    Enum.map(1..n, fn i ->
      {String.to_atom("#{my_atom}#{i}"), my_atom}
    end)
  end

  def rand_uniform(a, b) do
    :rand.uniform() * (b - a) + a
  end

  def generate_space_positions(population, a, b) do
    population
    |> Enum.map(fn {nombre, tipo} -> {nombre, tipo, {rand_uniform(a, b), rand_uniform(a, b)}} end)
  end

  def create_node(node) do
    {name, my_atom, pos, neighbours} = node

    actor =
      cond do
        my_atom == :Child -> EpidemicSimulator.Child
        my_atom == :Adult -> EpidemicSimulator.Adult
      end

    {:ok, _pid} =
      DynamicSupervisor.start_child(
        EpidemicSimulator.PopulationSupervisor,
        {actor, [name, pos, neighbours]}
      )
  end

  def distance({_, {x1, y1}}, {_, {x2, y2}}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  def create_neig(population, node) do
    {name, atom, point} = node

    neighbors =
      population
      |> Enum.filter(fn {other_name, _, _} -> other_name != name end)
      |> Enum.map(fn {other_name, atom, p} ->
        {other_name, atom, p, distance({name, point}, {other_name, p})}
      end)
      |> Enum.sort_by(fn {_, _, _, dist} -> dist end)
      |> Enum.filter(fn {_, _, _, distance} -> distance < 1 end)
      |> Enum.map(fn {other_name, _, _, _} -> other_name end)

    {name, atom, point, neighbors}
  end

  def generate_neig(population) do
    population |> Enum.map(fn node -> create_neig(population, node) end)
  end

  def create_population do
    IO.puts("How many adults do you want to create?")
    adults = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("How many children do you want to create?")
    children = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Creating population with #{adults} adults and #{children} children")
    create_population(adults, children)
  end

  def create_population(adults, childs) do
    GenServer.call(@me, [:create_population, adults, childs])
  end

  def create_virus do
    IO.puts("Insert the virality:")
    virality = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Insert incubation time (in seconds):")
    incubation_time = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Insert sick time (in seconds):")
    sick_time = IO.gets("") |> String.trim() |> String.to_integer()

    IO.puts("Insert lethality (number between 0 and 1):")
    lethality = IO.gets("") |> String.trim() |> String.to_float()

    create_virus(virality, incubation_time, sick_time, lethality)
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

    GenServer.cast(MedicalCenter, :plot)
    GenServer.cast(@me, {:simulate_virus, time})
  end

  def amount_of(health_status) do
    GenServer.call(@me, {:amount_of, health_status})
  end

  def stop_simulation() do
    GenServer.cast(@me, :stop_simulation)
  end

  # private
  defp collect_population_health_status(population) do
    Enum.reduce(population, %{}, fn person, acc ->
      health_status = GenServer.call(person, :health_status)
      Map.update(acc, health_status, 1, &(&1 + 1))
    end)
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
  def handle_call(:population, _, state) do
    {:reply, state.population, state}
  end

  @impl true
  def handle_call(:virus, _, state) do
    {:reply, state.virus, state}
  end

  @impl true
  def handle_call([:create_population, adult_n, child_n], _from, state) do
    # Creo mi poblacion
    childs = create_persons(:Child, child_n)
    adults = create_persons(:Adult, adult_n)
    population = childs ++ adults

    # le asignamos a la poblacion las posiciones (x,y) entre a,b y asignamos sus vecinos más cercanos
    population = population |> generate_space_positions(0, 5) |> generate_neig

    # Lanzo mis nodos poblacion
    population |> Enum.map(fn node -> create_node(node) end)

    # Guardo el estado
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

    new_population_health_status = collect_population_health_status(state.population)

    new_state = %{
      state
      | population_health_status: new_population_health_status
    }

    GenServer.cast(MedicalCenter, :plot)

    IO.puts("")
    IO.puts("-------------------")
    IO.puts("Simulation finished")
    IO.puts("Simulation time: #{inspect(simulation_time)}")
    IO.puts("Health status: #{inspect(new_population_health_status)}")

    {:noreply, new_state}
  end
end
