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
    incubation_time = virus.incubation_time

    new_health_status =
      if(state.health_status == :healthy) do
        if virus_beats_immune_system?(state.contagion_resistance) do
          start_incubating_virus(incubation_time, state.name)
          IO.puts("#{state.name}: I am incubating virus")

          :incubating
        else
          IO.puts("#{state.name}: Didn't get the virus")
          :healthy
        end
      else
        state.health_status
      end

    %{state | health_status: new_health_status, virus: virus}
  end

  def infect_neighbours(neighbours, virus) do
    amount_of_neighbours_to_infect = virus.virality

    Enum.each(1..amount_of_neighbours_to_infect, fn _ ->
      neighbour_to_infect = Enum.random(neighbours)
      GenServer.cast(neighbour_to_infect, {:infect, virus})
    end)
  end

  defp start_incubating_virus(incubation_time, name) do
    timer_identifier =  String.to_atom("#{name}_timer")
    GenServer.start_link(EpidemicSimulator.Timer, :ok, name: timer_identifier)
    GenServer.cast(timer_identifier, {:start, incubation_time, name, :get_sick})
  end

  defp virus_beats_immune_system?(contagion_resistance) do
    contagion_resistance < :rand.uniform()
  end
end
