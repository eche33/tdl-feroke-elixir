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
    result = GenServer.call(@me, :population_health_status)

    {:ok, amount} = Map.fetch(result, :sick)
    amount
  end

  def amount_of_healthy_people() do
    result = GenServer.call(@me, :population_health_status)

    {:ok, amount} = Map.fetch(result, :healthy)
    amount
  end

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

  defp update_health_status_map(population, health_status_map) do
    Enum.reduce(population, health_status_map, fn person, acc ->
      health_status = GenServer.call(person, :health_status)
      Map.update(acc, health_status, 1, &(&1 + 1))
    end)
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

    new_state = %{state | population: population, population_health_status: %{:healthy => length(population)}}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:population_health_status, _from, state) do
    {:reply, state.population_health_status, state}
  end

  @impl true
  def handle_call(:simulation_running?, _from, state) do
    sick_people = state.population_health_status[:sick]

    response = sick_people != length(state.population)

    {:reply, response, state}
  end

  @impl true
  def handle_cast({:notify_health_change, health_status, previous_health_status}, state) do
    population_health_status = state.population_health_status

    temp_map = Map.update(population_health_status, health_status, 1, &(&1 + 1))
    new_population_health_status = Map.update(temp_map, previous_health_status, 1, &(&1 - 1))

    new_state = %{state | population_health_status: new_population_health_status}

    {:noreply, new_state}
  end

end
