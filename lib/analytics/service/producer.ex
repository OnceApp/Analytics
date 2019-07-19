defmodule Analytics.Producer do
  use GenStage
  require Logger

  @interval_pull_in_milliseconds Application.fetch_env!(
                                   :analytics,
                                   :interval_pull_in_milliseconds
                                 )
  @max_events Application.fetch_env!(:analytics, :max_events)

  def start_link(type) do
    GenStage.start_link(__MODULE__, type, name: name(type))
  end

  @impl true
  def init(type) do
    Process.flag(:trap_exit, true)
    pid_to_subscribe = self()

    Analytics.ConsumerDynamicSupervisor.start_child(type, pid_to_subscribe)
    tick()
    {:producer, {{type.create_or_get_queue(), 0}, type}}
  end

  @impl true
  def terminate(_reason, {{queue, _}, type} = state) do
    type.merge(queue)
    Analytics.DispatchServer.dispatch(type)
    state
  end

  def name(type), do: {:via, Registry, {Analytics.Registry, {:analytics_producer_registry, type}}}
  @impl true
  def handle_info({:EXIT, _pid, reason}, {{queue, _pending_demand}, type} = state) do
    type.merge(queue)
    {:stop, :normal, state}
  end

  @impl true
  def handle_info(:tick, {{queue, pending_demand}, type} = state) do
    tick()

    if length(queue) < @max_events do
      items = apply(type, :create_batches_and_flush, [])
      queue = items ++ queue
      {events, state} = dispatch_events(queue, pending_demand, [])
      {:noreply, events, {state, type}}
    else
      {:noreply, [], state}
    end
  end

  defp tick(), do: Process.send_after(self(), :tick, @interval_pull_in_milliseconds)

  @impl true
  def handle_demand(incoming_demand, {{queue, pending_demand}, type}) do
    {events, state} = dispatch_events(queue, incoming_demand + pending_demand, [])
    {:noreply, events, {state, type}}
  end

  defp dispatch_events(queue, 0, events) do
    {Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, _events) do
    {events, queue} = Enum.split(queue, demand)
    {Enum.reverse(events), {queue, demand - length(events)}}
  end
end
