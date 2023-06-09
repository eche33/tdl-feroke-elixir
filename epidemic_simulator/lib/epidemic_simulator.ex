defmodule EpidemicSimulator do
  use GenServer

  defstruct [:population, :population_health_status]

  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  def create_population(adults, childs) do
    GenServer.call(@me, [:create_population, adults, childs])
  end

  def simulate_virus(first_infected_person) do
    GenServer.cast(first_infected_person, :infect)
  end

  def amount_of_sick_people() do
    GenServer.call(@me, :amount_of_sick_people)
  end

  def amount_of_healthy_people() do
    GenServer.call(@me, :amount_of_healthy_people)
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
    initial_state = %@me{population: [], population_health_status: %{}}

    {:ok, initial_state}
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

  def handle_call(:amount_of_sick_people, _, state) do
    result =
      Enum.count(state.population, fn person ->
        GenServer.call(person, :is_sick)
      end)

    {:reply, result, state}
  end

  def handle_call(:amount_of_healthy_people, _, state) do
    result =
      Enum.count(state.population, fn person ->
        GenServer.call(person, :is_healthy)
      end)

    {:reply, result, state}
  end

  def handle_cast(:stop_simulation, state) do
    Enum.each(state.population, fn person ->
      GenServer.cast(person, :stop_simulating)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call(:simulation_running?, _from, state) do
    sick_people = state.population_health_status[:sick]

    response = sick_people != length(state.population)

    {:reply, response, state}
  end
end
