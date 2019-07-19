use Mix.Config

config :analytics,
  adapter: Analytics.Adapter.Null,
  kinesis_streams: %{},
  max_events: 2,
  batch_size: 1,
  interval_pull_in_milliseconds: 100
