use Mix.Config

config :ex_aws,
  access_key_id: [],
  secret_access_key: []
config :analytics,
  adapter: Analytics.Adapter.Null,
  kinesis_streams: %{},
  max_events: 50,
  batch_size: 100,
  interval_pull_in_milliseconds: 1000,
  ets_table_name: :analytics_queue,
  aws_region: "eu-west-1"

case Mix.env() do
  :test -> import_config("test.exs")
  :local -> import_config "#{Mix.env()}.exs"
  _ -> :ok
end
