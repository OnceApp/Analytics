defmodule Analytics.Adapter.Null do
  def send_data(_type, _data) do
    Process.sleep(Enum.random(100..250))
    :ok
  end
end
