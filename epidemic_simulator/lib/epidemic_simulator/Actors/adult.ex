defmodule EpidemicSimulator.Adult do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name] , name: name)
  end

  #################################################

  @impl true
  def init([name]) do
    {:ok, [name]}
  end

end
