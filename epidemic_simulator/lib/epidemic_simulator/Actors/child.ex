defmodule EpidemicSimulator.Child do
  use GenServer

  def start_link([name, neighbours]) do
    GenServer.start_link(__MODULE__, [name, neighbours] , name: name)
  end

  @impl true
  def init([name, neighbours]) do
    neighbours_without_me = List.delete(neighbours, name)
    IO.puts("#{inspect name}")
    IO.puts("#{inspect neighbours_without_me}")
    {:ok, [name, neighbours_without_me]}
  end
end
