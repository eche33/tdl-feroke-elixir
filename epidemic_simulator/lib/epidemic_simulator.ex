defmodule EpidemicSimulator do
  @moduledoc """
  Documentation for `EpidemicSimulator`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> EpidemicSimulator.hello()
      :world

  """
  def hello do
    :world
  end

  def create_population(adults, children) do
    # For each child, create a child actor
    Enum.each(1..children, fn(i) ->
      create_child(String.to_atom("Child#{i}"))
    end)

    # For each adult, create an adult actor
    Enum.each(1..adults, fn(i) ->
      create_adult(String.to_atom("Adult#{i}"))
    end)
  end

  defp create_child(name) do
    {:ok, _pid} = DynamicSupervisor.start_child(EpidemicSimulator.ActorSupervisor, {EpidemicSimulator.Child, name})
  end

  defp create_adult(name) do
    {:ok, _pid} = DynamicSupervisor.start_child(EpidemicSimulator.ActorSupervisor, {EpidemicSimulator.Adult, name})
  end

end
