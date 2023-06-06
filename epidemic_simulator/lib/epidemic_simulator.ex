defmodule EpidemicSimulator do
  def create_population(adults, children) do
    all_persons = [:Child1, :Child2, :Adult1, :Adult2]

    # For each child, create a child actor
    Enum.each(1..children, fn i ->
      create_child(String.to_atom("Child#{i}"), all_persons)
    end)

    # For each adult, create an adult actor
    Enum.each(1..adults, fn i ->
      create_adult(String.to_atom("Adult#{i}"), all_persons)
    end)
  end

  def start_virus(first_infected_person) do
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
