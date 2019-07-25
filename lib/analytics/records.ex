defmodule Analytics.Records do
  @callback handle_event(payload :: [tuple()]) :: no_return()
  defmacro __using__(_) do
    quote location: :keep do
      @batch_size Application.fetch_env!(:analytics, :batch_size)
      use GenServer

      @behaviour Analytics.Records
      import Kernel
      import Analytics
      @impl true

      def start_link, do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

      def init(_) do
        :ets.new(ets_table_name(), [
          :named_table,
          :public,
          read_concurrency: true,
          write_concurrency: true
        ])

        create_or_get_queue()
        Analytics.ProducerSupervisor.start_child(__MODULE__)
        {:ok, nil}
      end

      defp ets_table_name, do: :"#{__MODULE__}.Queue"

      defp send_record(payload) do
        start_server_unless_running()
        add(payload)
      end

      defp start_server_unless_running,
        do: __MODULE__ |> GenServer.whereis() |> start_server_unless_running()

      defp start_server_unless_running(nil),
        do: Analytics.RecordsSupervisor.start_child(__MODULE__)

      defp start_server_unless_running(_pid), do: nil

      def create_batches_and_flush,
        do: GenServer.call(__MODULE__, :create_batches_and_flush)

      defp add(payload), do: GenServer.call(__MODULE__, {:add, payload})
      def merge(item), do: GenServer.call(__MODULE__, {:merge, item})

      def handle_call({:merge, queue_to_merge}, _from, state) do
        case get_queue_from_ets() do
          {:ok, queue} ->
            queue =
              Enum.flat_map(queue_to_merge, fn
                list when is_list(list) -> list
                elem -> [elem]
              end) ++ queue

            :ets.insert(ets_table_name(), {__MODULE__, queue})
            {:reply, queue, state}

          :error ->
            {:reply, {:error, :queue_not_found}, state}
        end
      end

      def handle_call({:add, item}, _from, state) do
        case get_queue_from_ets() do
          {:ok, queue} ->
            :ets.insert(ets_table_name(), {__MODULE__, [item | queue]})
            {:reply, :ok, state}

          :error ->
            {:reply, :queue_not_found, state}
        end
      end

      def handle_call(:create_batches_and_flush, _from, state) do
        case get_queue_from_ets() do
          {:ok, items} ->
            :ets.insert(ets_table_name(), {__MODULE__, []})
            {:reply, items |> Enum.reverse() |> Enum.chunk_every(@batch_size), state}

          :error ->
            {:reply, {:error, :queue_not_found}, state}
        end
      end

      defp create_queue, do: :ets.insert(ets_table_name(), {__MODULE__, []})

      def create_or_get_queue do
        case get_queue_from_ets() do
          {:ok, queue} ->
            queue

          :error ->
            create_queue()
            :queue.new()
        end
      end

      defp get_queue_from_ets do
        name = __MODULE__

        case :ets.lookup(ets_table_name(), name) do
          [{^name, queue}] -> {:ok, queue}
          [] -> :error
        end
      end
    end
  end
end
