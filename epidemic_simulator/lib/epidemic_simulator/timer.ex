defmodule EpidemicSimulator.Timer do
  use GenServer

  @me __MODULE__

  def start_timer(timer_name, caller_name, time) do
    GenServer.start_link(@me, :ok, name: timer_name)
    GenServer.cast(timer_name, {:start, time, caller_name})
  end

  def start_link(opts) do
    GenServer.start_link(@me, :ok, opts)
  end

  @impl true
  def init(:ok) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:start, time, name}, state) do
    :timer.sleep(:timer.seconds(time))

    GenServer.cast(name, :ring)
    {:noreply, state}
  end
end
