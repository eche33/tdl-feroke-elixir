defmodule Gossipstart do
  use Application

  @impl true
  def start(_type, _args) do
    Gossipstart.Supervisor.start_link(name: Gossipstart.Supervisor)
  end
end
