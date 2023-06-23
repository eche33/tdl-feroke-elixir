defmodule EpidemicSimulator.Person do
  def initialize_person_with(name, pos, neighbours, contagion_resistance, comorbidities) do
    neighbours_without_me = List.delete(neighbours, name)
    IO.puts("I'm #{inspect(name)} #{inspect(pos)}")
    IO.puts("#{name}: my neighnours are #{inspect(neighbours_without_me)}")

    initial_state = %EpidemicSimulator.Structs.CitizenInformation{
      name: name,
      pos: pos,
      neighbours: neighbours_without_me,
      health_status: :healthy,
      contagion_resistance: contagion_resistance,
      comorbidities: comorbidities,
      simulation_running: true,
      virus: nil
    }

    GenServer.cast(
      MedicalCenter,
      {:census, initial_state.name, initial_state.pos, initial_state.health_status}
    )

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

    GenServer.cast(MedicalCenter, {:census, state.name, state.pos, new_health_status})

    %{state | health_status: new_health_status, virus: virus}
  end

  def infect_neighbours(neighbours, virus) do
    amount_of_neighbours_to_infect = virus.virality

    Enum.each(1..amount_of_neighbours_to_infect, fn _ ->
      neighbour_to_infect = Enum.random(neighbours)
      GenServer.cast(neighbour_to_infect, {:infect, virus})
    end)
  end

  def convalescence_period(name, virus) do
    sick_time = virus.sick_time
    timer_identifier = String.to_atom("#{name}_timer")
    EpidemicSimulator.Timer.start_timer(timer_identifier, name, sick_time)
  end

  def heal_or_die(virus, comorbidities) do
    if virus_kills_person?(virus.lethality, comorbidities) do
      :dead
    else
      :immune
    end
  end

  def get_next_health_status(health_status, virus, comorbidities) do
    case health_status do
      :incubating -> :sick
      :sick -> heal_or_die(virus, comorbidities)
      _ -> health_status
    end
  end

  def act_based_on_new_health_status(new_health_status, state) do
    GenServer.cast(MedicalCenter, {:census, state.name, state.pos, new_health_status})

    new_state =
      case new_health_status do
        :sick ->
          if state.simulation_running do
            convalescence_period(state.name, state.virus)
            infect_neighbours(state.neighbours, state.virus)
          end

          IO.puts("#{state.name}: I got sick")
          %{state | health_status: :sick}

        :immune ->
          IO.puts("#{state.name}: I'm immune now!")
          %{state | health_status: :immune}

        :dead ->
          IO.puts("#{state.name}: I died :(")
          %{state | health_status: :dead}
      end

    new_state
  end

  defp virus_kills_person?(lethality, comorbidities) do
    lethality + comorbidities > :rand.uniform()
  end

  defp start_incubating_virus(incubation_time, name) do
    timer_identifier = String.to_atom("#{name}_timer")
    EpidemicSimulator.Timer.start_timer(timer_identifier, name, incubation_time)
  end

  defp virus_beats_immune_system?(contagion_resistance) do
    contagion_resistance < :rand.uniform()
  end
end
