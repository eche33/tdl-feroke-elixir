defmodule EpidemicSimulator.Timer do
  use GenServer

  @me __MODULE__

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:start, time, name, callback_message}, state) do
    :timer.sleep(:timer.seconds(time))

    GenServer.cast(name, callback_message)
    {:noreply, state}
  end
end
