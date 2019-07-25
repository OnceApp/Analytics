defmodule Analytics.Adapter.Kinesis do
  require Logger

  defmodule Message do
    defstruct([:partition_key, :data])
  end

  @stream_map Application.fetch_env!(:analytics, :kinesis_streams)
  @aws_region Application.fetch_env!(:analytics, :aws_region)

  @spec send_data(any(), [%{data: binary(), partition_key: binary()}]) :: :ok
  def send_data(type, message) do
    try do
      with {:ok, _res} <- make_request(type, message) do
        :ok
      else
        {:error, reason} ->
          raise reason
      end
    rescue
      e ->
        Logger.error("Unable to send data to kinesis #{inspect(e.message)}",
          backtrace: __STACKTRACE__
        )

        :ok
    end
  end

  defp make_request(type, messages),
    do:
      ExAws.Kinesis.put_records(stream_name(type), messages) |> ExAws.request(region: @aws_region)

  defp stream_name(type), do: Map.get(@stream_map, type)
end
