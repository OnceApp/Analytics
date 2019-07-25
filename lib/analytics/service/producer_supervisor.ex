defmodule Analytics.ProducerSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_child(type) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Analytics.Producer,
      start: {Analytics.Producer, :start_link, [type]},
      restart: :transient
    })
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
