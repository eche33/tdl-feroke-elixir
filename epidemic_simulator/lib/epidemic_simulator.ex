defmodule EpidemicSimulator do
  use GenServer

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
    3
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
    population = []

    {:ok, population}
  end

  @impl true
  def handle_call([:create_population, adults, children], _from, _state) do
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

    {:reply, :ok, population}
  end

  @impl true
  def handle_call(:population_health_status, _from, state) do
    population = state

    health_status_map = %{}

    new_health_status_map = update_health_status_map(population, health_status_map)

    {:reply, new_health_status_map, state}
  end

end
