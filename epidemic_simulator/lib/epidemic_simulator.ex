defmodule EpidemicSimulator do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def create_population(adults, childs) do
    GenServer.call(__MODULE__, [:create_population, adults, childs])
  end

  def simulate_virus(first_infected_person) do
    GenServer.cast(first_infected_person, :infect)
  end

  def amount_of_sick_people() do
    3
  end

  def amount_of_healthy_people() do
    1
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

  @impl true
  def init(:ok) do
    population = []

    {:ok, population}
  end

  @impl true
  def handle_call([:create_population, adults, children], _from, _state) do
    childs = Enum.map(1..children, fn i ->
         String.to_atom("Child#{i}")
    end)

    adults = Enum.map(1..adults, fn i ->
        String.to_atom("Adult#{i}")
    end)

    population = childs ++ adults

    IO.puts("Population: #{inspect (population)}")

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
end
