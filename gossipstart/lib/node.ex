defmodule Gossipstart.Node do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name] , name: name)
  end

  @impl true
  def init([name]) do
    {:ok, [name]}
  end

  @impl true
  def handle_cast({:rumor, content}, state) do
    [name] = state

    everybody_knows_the_rumor = Gossipstart.GossipHandler.everybody_knows_the_rumor?()

    if not everybody_knows_the_rumor do
      IO.puts("My name is #{name}")
      node_to_rumor = Gossipstart.GossipHandler.get_node_to_rumor(name)
      # IO.puts("Node to rumor: #{inspect node_to_rumor}")
      IO.puts "#{inspect self()}: Rumor received: #{content}"

      Gossipstart.GossipHandler.notify_rumor_received(name)
      GenServer.cast(node_to_rumor, {:rumor, content})
    end

    new_state = [name]
    {:noreply, new_state}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in Gossipstart.Registry: #{inspect(msg)}")
    {:noreply, state}
  end

end
