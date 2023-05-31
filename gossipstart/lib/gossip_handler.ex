defmodule Gossipstart.GossipHandler do
  use GenServer
  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def add_nodes(nodes) do
    GenServer.cast(@me, {:add_nodes, nodes})
  end

  def get_node_to_rumor(node_asking) do
    GenServer.call(@me, {:get_node_to_rumor, node_asking})
  end

  def notify_rumor_received(node) do
    GenServer.cast(@me, {:notify_rumor_received, node})
  end

  defp update_nodes_that_received_rumor(nodes_that_received_rumor, node) do
    if Enum.member?(nodes_that_received_rumor, node) do
      nodes_that_received_rumor
    else
      [node | nodes_that_received_rumor]
    end
  end

  @impl true
  def init(:ok) do
    nodes = []
    nodes_that_received_rumor = []
    {:ok, [nodes, nodes_that_received_rumor]}
  end

  @impl true
  def handle_call({:get_node_to_rumor, node_asking}, _from, state) do
    [nodes, _] = state
    candidates = List.delete(nodes, node_asking)
    selected_node = Enum.random(candidates)
    {:reply, selected_node, state}
  end

  @impl true
  def handle_cast({:add_nodes, nodes}, state) do
    [_, nodes_that_received_rumor] = state
    {:noreply, [nodes, nodes_that_received_rumor]}
  end

  @impl true
  def handle_cast({:notify_rumor_received, node}, state) do
    [nodes, nodes_that_received_rumor] = state

    nodes_that_received_rumor = update_nodes_that_received_rumor(nodes_that_received_rumor, node)

    if Enum.count(nodes_that_received_rumor) == Enum.count(nodes) do
      IO.puts("All nodes received the rumor")
      #Process.exit(self(), :normal)
    end

    new_state = [nodes, nodes_that_received_rumor]
    {:noreply, new_state}
  end

end
