defmodule Gossipstart.Node do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, [name] , name: name)
  end

  @impl true
  def init([name]) do
    {:ok, [name, 4]}
  end

  @impl true
  def handle_cast({:rumor, content}, state) do
    [name, remaining_rumor_times] = state

    IO.puts("My name is #{name}")

    node_to_rumor = Gossipstart.GossipHandler.get_node_to_rumor(name)
    IO.puts("Node to rumor: #{inspect node_to_rumor}")

    if remaining_rumor_times > 0 do
      IO.puts "#{inspect self()}: Rumor received: #{content}"
      Gossipstart.GossipHandler.notify_rumor_received(name)
      GenServer.cast(node_to_rumor, {:rumor, content})
    end

    new_state = [name, remaining_rumor_times - 1]
    {:noreply, new_state}
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in Gossipstart.Registry: #{inspect(msg)}")
    {:noreply, state}
  end

end
