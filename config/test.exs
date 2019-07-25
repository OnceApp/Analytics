use Mix.Config

config :analytics,
  adapter: Analytics.Adapter.Test,
  kinesis_streams: %{},
  batch_size: 5,
  interval_pull_in_milliseconds: 500
