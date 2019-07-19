defmodule Analytics.Adapter.Test do
  use GenServer
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok), do: {:ok, %{}}

  def send_data(type, data), do: GenServer.call(__MODULE__, {:add, type, data})
  def clear(type), do: GenServer.call(__MODULE__, {:clear, type})
  def get(type), do: GenServer.call(__MODULE__, {:get, type})

  def handle_call({:add, type, data}, _from, state) do
    {:reply, :ok, Map.update(state, type, [data], fn event -> [data | event] end)}
  end

  def handle_call({:clear, type}, _from, state) do
    {:reply, :ok, Map.update(state, type, [], fn _event -> [] end)}
  end

  def handle_call({:get, type}, _from, state) do
    {:reply, Map.get(state, type, []) |> Enum.reverse(),
     Map.update(state, type, [], fn _event -> [] end)}
  end
end
