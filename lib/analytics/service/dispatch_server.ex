defmodule Analytics.DispatchServer do
  use GenServer
  
  def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  
  @impl true
  def init(_opts), do: {:ok, nil}

  def dispatch(type), do: GenServer.cast(__MODULE__, {:dispatch, type})

  def handle_cast({:dispatch, type}, state) do
    type.create_batches_and_flush()
    |> Task.async_stream(fn event -> Analytics.Consumer.start_link(type, event) end)
    |> Stream.run()

    {:noreply, state}
  end
end
