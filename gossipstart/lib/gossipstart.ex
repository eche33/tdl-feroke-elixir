defmodule Gossipstart do
  use Application
  @moduledoc """
  Documentation for `Gossipstart`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Gossipstart.hello()
      :world

  """
  # def hello_proccesses do
  #   {:ok, node1} = GenServer.start_link(Gossipstart.Node, [2], name: :Node1)
  #   IO.puts("Node1: #{inspect node1}")
  #   {:ok, node2} = GenServer.start_link(Gossipstart.Node, [3], name: :Node2)
  #   IO.puts("Node2: #{inspect node2}")
  #   {:ok, node3} = GenServer.start_link(Gossipstart.Node, [4], name: :Node3)
  #   IO.puts("Node3: #{inspect node3}")
  #   {:ok, node4} = GenServer.start_link(Gossipstart.Node, [1], name: :Node4)
  #   IO.puts("Node4: #{inspect node4}")

  #   # Tendríamos que tener un registry que maneje los nodos
  #   # Y a su vez un supervisor que maneje el registry

  #   # Gossipstart.Node.send_message(node1, node2, "¡Hola, proceso 2!")
  #   # Gossipstart.Node.send_message(node3, node4, "¡Hola, proceso 4!")

  #   total_nodes = 4
  #   GenServer.call(:Node1, {:rumor, "Shhh", total_nodes - 1})
  # end

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    Gossipstart.Supervisor.start_link(name: Gossipstart.Supervisor)
  end

end
