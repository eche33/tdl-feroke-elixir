defmodule Gossipstart.Node do
  use GenServer

  def start_link([name, node_to_rumor]) do
    IO.puts("Soy el nodo #{name} y mi vecino es #{node_to_rumor}")
    GenServer.start_link(__MODULE__, [node_to_rumor] , name: name)
  end

  def send_message(node_from, node_to_call, message) do
    GenServer.call(node_from, {:send_message, node_to_call, message})
  end

  @impl true
  def init([node_number_to_rumor]) do
    {:ok, [node_number_to_rumor]}
  end

  @impl true
  def handle_call({:receive_message, content}, from, state) do
    IO.puts "#{inspect self()}: Mensaje recibido: #{content} de #{inspect from}"
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:send_message, node_to_call, content}, _from, state) do
    IO.puts "#{inspect self()}: Mensaje enviado: #{content} a #{inspect node_to_call}"
    GenServer.call(node_to_call, {:receive_message, content})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:rumor, content, total_nodes}, from, state) do
    [node_to_rumor] = state

    if total_nodes == 0 do
      # IO.puts("#{inspect self()}: contador de rumor: #{rumor_sent?}")
      # IO.puts("#{inspect self()}: total de nodos: #{total_nodes}")
      IO.puts("#{inspect self()}: Rumor recibido: #{content} de #{inspect from}")
      IO.puts("Todos tienen el rumor")
      System.halt(0)
      {:reply, :ok, state}
    end

    if total_nodes > 0 do
      # IO.puts("#{inspect self()}: contador de rumor: #{rumor_sent?}")
      # IO.puts("#{inspect self()}: total de nodos: #{total_nodes}")
      IO.puts "#{inspect self()}: Rumor recibido: #{content} de #{inspect from}"
      node_alias = String.to_atom("Node#{node_to_rumor}")
      GenServer.call(node_alias, {:rumor, content, total_nodes - 1})
      {:reply, :ok, state}
    end
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
