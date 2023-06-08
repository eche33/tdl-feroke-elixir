defmodule EpidemicSimulator.Child do
  use GenServer

  def start_link([name, neighbours]) do
    GenServer.start_link(__MODULE__, [name, neighbours], name: name)
  end

  @impl true
  def init([name, neighbours]) do
    neighbours_without_me = List.delete(neighbours, name)
    IO.puts("I'm #{inspect(name)}")
    IO.puts("#{name}: my neighnours are #{inspect(neighbours_without_me)}")

    initial_state = %EpidemicSimulator.Structs.CitizenInformation{
      name: name,
      neighbours: neighbours_without_me,
      health_status: :healthy,
      contagion_resistance: 0
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_cast(:infect, state) do

    [first_neighbour | _] = state.neighbours

    new_health_status =
      case state.health_status do
        :healthy ->
          IO.puts("#{state.name}: me enferme :(")
          GenServer.cast(first_neighbour, :infect)

          :sick

        :sick ->
          IO.puts("#{state.name}: andapalla")

          :sick
      end

    new_state = %{state | health_status: new_health_status}
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:health_status, _from, state) do
    {:reply, state.health_status, state}
  end

end
