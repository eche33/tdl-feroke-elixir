defmodule EpidemicSimulator.Person do
  def initialize_person_with(name, neighbours, contagion_resistance) do
    neighbours_without_me = List.delete(neighbours, name)
    IO.puts("I'm #{inspect(name)}")
    IO.puts("#{name}: my neighnours are #{inspect(neighbours_without_me)}")

    initial_state = %EpidemicSimulator.Structs.CitizenInformation{
      name: name,
      neighbours: neighbours_without_me,
      health_status: :healthy,
      contagion_resistance: contagion_resistance,
      simulation_running: true,
      virus: nil
    }

    initial_state
  end

  def virus_enter_the_body(state, virus) do
    incubation_time = 1

    new_health_status =
      if(state.health_status == :healthy) do
        if get_sick?(state.contagion_resistance) do
          start_incubating_virus(incubation_time, state.name)
          IO.puts("#{state.name}: i am incubating virus")

          :incubating
        else
          IO.puts("#{state.name}: Zafé, no me contagié")
          :healthy
        end
      else
        state.health_status
      end

    %{state | health_status: new_health_status, virus: virus}
  end

  def infect_neighbours(neighbours, virus) do
    Enum.each(1..virus.virality, fn _ ->
      neighbour_to_infect = Enum.random(neighbours)
      GenServer.cast(neighbour_to_infect, {:infect, virus})
    end)
  end

  defp start_incubating_virus(incubation_time, name) do
    GenServer.start_link(EpidemicSimulator.Timer, :ok, name: String.to_atom("#{name}_timer"))
    GenServer.cast(String.to_atom("#{name}_timer"), {:start, incubation_time, name, :get_sick})
  end

  defp get_sick?(contagion_resistance) do
    contagion_resistance = contagion_resistance

    contagion_resistance < :rand.uniform()
  end
end
