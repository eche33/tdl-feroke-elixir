defmodule EpidemicSimulator.Adult do
  use GenServer

  def start_link([name, neighbours]) do
    GenServer.start_link(__MODULE__, [name, neighbours], name: name)
  end

  @impl true
  def handle_cast(:infect, state) do
    [name, neighbours, health_status] = state
    [first_neighbour | _] = neighbours

    new_health_status = case health_status do
      :healthy ->
        IO.puts("Me enferme :( soy #{name}")
        GenServer.cast(first_neighbour, :infect)

        :sick
      :sick ->
        IO.puts("andapalla soy #{name}")

        :sick
    end

    {:noreply, [name, neighbours, new_health_status]}
  end

  @impl true
  def init([name, neighbours]) do
    neighbours_without_me = List.delete(neighbours, name)
    IO.puts("#{inspect(name)}")
    IO.puts("#{inspect(neighbours_without_me)}")

    {:ok, [name, neighbours_without_me, :healthy]}
  end
end
