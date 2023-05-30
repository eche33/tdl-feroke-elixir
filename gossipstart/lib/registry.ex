defmodule Gossipstart.Registry do
  use GenServer

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, rumor) do
    GenServer.call(server, {:create, rumor})
  end

  def create_node(server, node_name) do
    GenServer.cast(server, {:create_node, node_name})
  end

  def create_all_nodes(server) do
    GenServer.cast(server, {:create_all_nodes})
  end

  def received_rumor() do
    GenServer.call(@me, {:received_rumor})
  end

  ## Defining GenServer Callbacks

  @impl true
  def init(:ok) do
    {:ok, 2}
  end

  @impl true
  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  # @impl true
  # def handle_cast({:create, name}, {names, refs}) do
  #   if Map.has_key?(names, name) do
  #     {:noreply, {names, refs}}
  #   else
  #     {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
  #     ref = Process.monitor(pid)
  #     refs = Map.put(refs, ref, name)
  #     names = Map.put(names, name, pid)
  #     {:noreply, {names, refs}}
  #   end
  # end

  @impl true
  def handle_cast({:create_node, name}, state) do
    {:ok, pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, name})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:create_all_nodes}, state) do
    {:ok, pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, [:Node1, 2]})
    {:ok, pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, [:Node2, 1]})
    # {:ok, pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, [:Node3, 4]})
    # {:ok, pid} = DynamicSupervisor.start_child(Gossipstart.NodeSupervisor, {Gossipstart.Node, [:Node4, 1]})

    total_nodes = 2
    GenServer.cast(:Node1, {:rumor, "rumor", total_nodes - 1})

    {:noreply, state}
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

  @impl true
  def handle_call({:rumor_received}, from, count) do
    IO.puts("Node #{inspect from} received rumor")

    count = count - 1
    if count == 0 do
      IO.puts("Todos tienen el rumor")
      System.halt(0)
    else
      {:reply, count, count}
    end

  end



end
