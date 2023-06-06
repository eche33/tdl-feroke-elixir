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

  def everybody_knows_the_rumor?() do
    GenServer.call(@me, :everybody_knows_the_rumor?)
  end

  def reset_state() do
    GenServer.call(@me, :reset_state)
  end

  defp update_nodes_that_received_rumor(nodes_that_received_rumor, node) do
    if Enum.member?(nodes_that_received_rumor, node) do
      nodes_that_received_rumor
    else
      [node | nodes_that_received_rumor]
    end
  end

  defp update_node_status(node_name, rumor_known) do
    known_icon = if rumor_known, do: "●", else: "○"

    IO.puts("#{known_icon} #{node_name} - Rumor Known: #{rumor_known}")
  end

  @impl true
  def init(:ok) do
    nodes = []
    nodes_that_received_rumor = []
    steps_taken = 0
    {:ok, [nodes, nodes_that_received_rumor, steps_taken]}
  end

  @impl true
  def handle_call({:get_node_to_rumor, node_asking}, _from, state) do
    [nodes, _, _] = state
    candidates = List.delete(nodes, node_asking)
    selected_node = Enum.random(candidates)
    {:reply, selected_node, state}
  end

  @impl true
  def handle_call(:everybody_knows_the_rumor?, _from, state) do
    [nodes, nodes_that_received_rumor, _] = state

    if Enum.count(nodes_that_received_rumor) == Enum.count(nodes) do
      {:reply, true, state}
    else
      {:reply, false, state}
    end

  end

  @impl true
  def handle_call(:reset_state, _from, state) do
    [nodes, _, _] = state

    new_state = [nodes, [], 0]
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:add_nodes, nodes}, state) do
    [_, nodes_that_received_rumor, steps_taken] = state
    {:noreply, [nodes, nodes_that_received_rumor, steps_taken]}
  end

  @impl true
  def handle_cast({:notify_rumor_received, node}, state) do
    [nodes, nodes_that_received_rumor, steps_taken] = state

    nodes_that_received_rumor = update_nodes_that_received_rumor(nodes_that_received_rumor, node)


    nodes_that_dont_know_the_rumor = nodes -- nodes_that_received_rumor
    Enum.each(nodes_that_dont_know_the_rumor, fn node ->
      update_node_status(node, false)
    end)


    Enum.each(nodes_that_received_rumor, fn node ->
      update_node_status(node, true)
    end)


    if Enum.count(nodes_that_received_rumor) == Enum.count(nodes) do
      IO.puts("All nodes received the rumor")
      IO.puts("Steps taken: #{steps_taken}")
      # Process.exit(self(), :normal)
    end

    new_state = [nodes, nodes_that_received_rumor, steps_taken + 1]
    {:noreply, new_state}
  end

end
