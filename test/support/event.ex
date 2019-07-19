defmodule Analytics.Records.Event do
  use Analytics.Records

  def record(value), do: send_record(value)

  @impl true
  def handle_event(events) do
    send_data(__MODULE__,"event", events)
  rescue
    exception ->
      reraise exception, __STACKTRACE__
  end
end
