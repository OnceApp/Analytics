defmodule Analytics.Consumer do
  require Logger
  @env Mix.env()
  def start_link(type, payload) do
    Task.start_link(fn ->
      try do
        if payload != [], do: apply(type, :handle_event, [payload])
      rescue
        exception ->
          handle_failure(
            exception,
            "Unable to send #{type} event to kinesis",
            payload,
            __STACKTRACE__
          )
      end
    end)
  end

  defp handle_failure(exception, error_message, payload, stacktrace) do
    if @env == :local do
      Logger.error(
        error_message <> " #{inspect({payload, exception, stacktrace}, limit: :infinity)}"
      )
    else
      Logger.error(error_message <> " #{inspect({payload, exception, stacktrace})}",
        backtrace: stacktrace
      )
    end
  end
end
