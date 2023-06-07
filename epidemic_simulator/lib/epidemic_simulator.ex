defmodule EpidemicSimulator do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    population = []

    {:ok, population}
  end

  def create_population(adults, childs) do
    GenServer.call(__MODULE__, [:create_population, adults, childs])
  end

  @impl true
  def handle_call([:create_population, adults, children], _from, _state) do
    # For each child, create a child actor
    childs = Enum.map(1..children, fn i ->
         String.to_atom("Child#{i}")
    end)

    # For each adult, create an adult actor
    adults = Enum.map(1..adults, fn i ->
        String.to_atom("Adult#{i}")
    end)

    IO.puts("#{inspect (childs++adults)}")

    {:reply, :ok, []}
  end

  def simulate_virus(first_infected_person) do
    GenServer.cast(first_infected_person, :infect)
  end

  def amount_of_sick_people() do
    3
  end

  defp create_child(name, neighbours) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        EpidemicSimulator.ActorSupervisor,
        {EpidemicSimulator.Child, [name, neighbours]}
      )
  end

  defp create_adult(name, neighbours) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        EpidemicSimulator.ActorSupervisor,
        {EpidemicSimulator.Adult, [name, neighbours]}
      )
  end
end
