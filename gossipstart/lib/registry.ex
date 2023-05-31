defmodule Gossipstart.Registry do
  use GenServer
  @me __MODULE__

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def create_gossip(number_of_nodes) do
    GenServer.call(@me, {:create_gossip, number_of_nodes})
  end

  def start_gossip(rumor) do
    GenServer.cast(@me, {:start_gossip, rumor})
  end

  defp create_node( name) do
    {:ok, _pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, name})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:start_gossip, rumor}, nodes) do
    random_node = Enum.random(nodes)
    IO.puts("Random initial node: #{inspect random_node}")

    GenServer.cast(random_node, {:rumor, rumor})

    {:noreply, nodes}
  end

  @impl true
  def handle_call({:create_gossip, number_of_nodes}, _from, _state) do
    nodes_list = []

    nodes = Enum.reduce(1..number_of_nodes, nodes_list, fn(i, acc) ->
      node_name = String.to_atom("Node#{i}")
      create_node(node_name)
      [node_name | acc]
    end)

    Gossipstart.GossipHandler.add_nodes(nodes)
    {:reply, :ok, nodes}
  end

end
