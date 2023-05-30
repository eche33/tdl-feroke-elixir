defmodule Gossipstart.Node do
  use GenServer

  def start_link(name) do
    IO.puts("Soy el nodo #{name}")
    GenServer.start_link(__MODULE__, [name] , name: name)
  end

  @impl true
  def init([name]) do
    {:ok, [name]}
  end

  @impl true
  def handle_call({:rumor, content, total_nodes}, from, state) do
    [name] = state

    IO.puts("My name is #{name}")

    node_to_rumor = Gossipstart.GossipHandler.get_node_to_rumor(name)
    IO.puts("Node to rumor: #{inspect node_to_rumor}")

    # if total_nodes == 0 do
    #   # IO.puts("#{inspect self()}: contador de rumor: #{rumor_sent?}")
    #   # IO.puts("#{inspect self()}: total de nodos: #{total_nodes}")
    #   IO.puts("#{inspect self()}: Rumor recibido: #{content} de #{inspect from}")
    #   IO.puts("Todos tienen el rumor")
    #   System.halt(0)
    #   {:reply, :ok, state}
    # end

    # if total_nodes > 0 do
    #   # IO.puts("#{inspect self()}: contador de rumor: #{rumor_sent?}")
    #   # IO.puts("#{inspect self()}: total de nodos: #{total_nodes}")
    #   IO.puts "#{inspect self()}: Rumor recibido: #{content} de #{inspect from}"
    #   node_alias = String.to_atom("Node#{node_to_rumor}")
    #   GenServer.call(node_alias, {:rumor, content, total_nodes - 1})
    #   {:reply, :ok, state}
    # end
  end

  @impl true
  def handle_cast({:rumor, content, total_nodes}, state) do
    [node_to_rumor] = state

    if total_nodes == 0 do
      # IO.puts("#{inspect self()}: contador de rumor: #{rumor_sent?}")
      # IO.puts("#{inspect self()}: total de nodos: #{total_nodes}")
      IO.puts("#{inspect self()}: Rumor recibido: #{content}")
      IO.puts("Todos tienen el rumor")
      System.halt(0)
      {:noreply, state}
    end

    if total_nodes > 0 do
      # IO.puts("#{inspect self()}: contador de rumor: #{rumor_sent?}")
      # IO.puts("#{inspect self()}: total de nodos: #{total_nodes}")
      IO.puts "#{inspect self()}: Rumor recibido: #{content} "
      node_alias = String.to_atom("Node#{node_to_rumor}")
      GenServer.cast(node_alias, {:rumor, content, total_nodes - 1})
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message in KV.Registry: #{inspect(msg)}")
    {:noreply, state}
  end

end
