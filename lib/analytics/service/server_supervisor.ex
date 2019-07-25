defmodule Analytics.ServerSupervisor do
  use Supervisor

  def start_link(), do: Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    children = [
      %{
        id: Analytics.DispatchServer,
        start: {Analytics.DispatchServer, :start_link, []}
      }
    ]

    Elixir.Supervisor.init(children, strategy: :one_for_one)
  end
end
