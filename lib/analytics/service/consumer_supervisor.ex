defmodule Analytics.ConsumerSupervisor do
  @max_events Application.fetch_env!(:analytics, :max_events)
  use ConsumerSupervisor

  def start_link(type, pid_to_subscribe) do
    ConsumerSupervisor.start_link(__MODULE__, {type, pid_to_subscribe}, name: name(type))
  end

  defp name(type),
    do: {:via, Registry, {Analytics.Registry, {:analytics_consumer_supervisors_registry, type}}}

  def init({type, pid_to_subscribe}) do
    children = [
      %{
        id: Analytics.Consumer,
        start: {Analytics.Consumer, :start_link, [type]},
        restart: :temporary
      }
    ]

    opts = [
      strategy: :one_for_one,
      subscribe_to: [{pid_to_subscribe, max_demand: @max_events, min_demand: 1}]
    ]

    ConsumerSupervisor.init(children, opts)
  end
end
