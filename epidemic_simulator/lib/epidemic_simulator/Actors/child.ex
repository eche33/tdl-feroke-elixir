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
      contagion_resistance: 0.3,
      simulation_running: true
    }

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
  def handle_cast({:infect, virus}, state) do
    new_health_status =
      case state.health_status do
        :healthy ->
          if (EpidemicSimulator.Helpers.ContagionHelper.get_sick?(state)) do
            IO.puts("#{state.name}: me enferme :(")

            :sick
          else
            IO.puts("#{state.name}: Zafé, no me contagié")
            :healthy
          end


        :sick ->
          :sick
      end

    if state.simulation_running and new_health_status == :sick do
      Enum.each(1..virus.virality, fn _ ->
        neighbour_to_infect = Enum.random(state.neighbours)
        GenServer.cast(neighbour_to_infect, {:infect, virus})
      end)
    end

    new_state = %{state | health_status: new_health_status}
    {:noreply, new_state}
  end

  def handle_cast(:stop_simulating, state) do
    new_state = %{state | simulation_running: false}
    {:noreply, new_state}
  end
end
