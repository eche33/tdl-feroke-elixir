defmodule Gossipstart.Registry do
  use GenServer
  @me __MODULE__

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def create(server, rumor) do
    GenServer.call(server, {:create, rumor})
  end

  def create_node(node_name) do
    GenServer.cast(@me, {:create_node, node_name})
  end

  def create_all_nodes(server) do
    GenServer.cast(server, {:create_all_nodes})
  end

  def create_gossip(number_of_nodes) do
    GenServer.call(@me, {:create_gossip, number_of_nodes})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, 2}
  end

  @impl true
  def handle_cast({:create_node, name}, state) do
    {:ok, _pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, name})
    {:noreply, state}
  end

  @impl true
  def handle_call({:create_gossip, number_of_nodes}, _from, state) do
    nodes_list = []

    nodes = Enum.reduce(1..number_of_nodes, nodes_list, fn(i, acc) ->
      node_name = String.to_atom("Node#{i}")
      create_node(node_name)
      [node_name | acc]
    end)

    IO.puts("Nodos creados: #{inspect nodes}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:create, rumor}, _from, state) do
    {:ok, node1} = GenServer.start_link(Gossipstart.Node, [2], name: :Node1)
    IO.puts("Node1: #{inspect node1}")
    {:ok, node2} = GenServer.start_link(Gossipstart.Node, [3], name: :Node2)
    IO.puts("Node2: #{inspect node2}")
    {:ok, node3} = GenServer.start_link(Gossipstart.Node, [4], name: :Node3)
    IO.puts("Node3: #{inspect node3}")
    {:ok, node4} = GenServer.start_link(Gossipstart.Node, [1], name: :Node4)
    IO.puts("Node4: #{inspect node4}")

    total_nodes = 4
    GenServer.call(:Node1, {:rumor, rumor, total_nodes - 1})
    {:reply, state}
  end

end
