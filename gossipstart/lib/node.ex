defmodule Gossipstart.Node do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name , name: name)
  end

  def send_message(node_from, node_to_call, message) do
    GenServer.call(node_from, {:send_message, node_to_call, message})
  end

  @impl true
  def init(name) do
    {:ok, %{}}
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
      {:no_reply, :ok, state}
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

end
