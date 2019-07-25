defmodule Analytics do
  import Kernel
  @adapter_module Application.fetch_env!(:analytics, :adapter) || Analytics.Adapter.Null

  def send_data(module, type, message), do: @adapter_module.send_data(type, message)
  def generate_event_id, do: :crypto.strong_rand_bytes(50) |> Base.encode16(case: :lower)
end
