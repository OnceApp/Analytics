defmodule Analytics.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, [keys: :unique, name: Analytics.Registry]},
      %{
        id: Analytics.ServerSupervisor,
        start: {Analytics.ServerSupervisor, :start_link, []}
      },
      {Analytics.ConsumerDynamicSupervisor, []},
      {Analytics.ProducerSupervisor, []},
      {Analytics.RecordsSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Analytics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
