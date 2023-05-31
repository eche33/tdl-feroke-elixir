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

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_call({:get_node_to_rumor, node_asking}, _from, nodes) do
    candidates = List.delete(nodes, node_asking)
    selected_node = Enum.random(candidates)
    {:reply, selected_node, nodes}
  end

  @impl true
  def handle_cast({:add_nodes, nodes}, _state) do
    {:noreply, nodes}
  end

end
