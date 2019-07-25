defmodule Analytics.RecordTest do
  use ExUnit.Case, async: false
  @dispatch_sleep 500
  @interval_pull_in_milliseconds Application.fetch_env!(
                                   :analytics,
                                   :interval_pull_in_milliseconds
                                 ) + @dispatch_sleep
  setup do
    pid = start_supervised!(Analytics.Adapter.Test)

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
      :ets.insert(Analytics.Records.Event.Queue, {Analytics.Records.Event, []})
    end)
  end

  test "Sending exact chunk size" do
    Enum.each(1..5, &Analytics.Records.Event.record/1)
    Process.sleep(@interval_pull_in_milliseconds)
    assert Analytics.Adapter.Test.get("event") == [[1, 2, 3, 4, 5]]
  end

  test "Sending three times the chunk size" do
    Enum.each(1..15, &Analytics.Records.Event.record/1)
    Process.sleep(@interval_pull_in_milliseconds)

    assert Analytics.Adapter.Test.get("event")
           |> Enum.flat_map(& &1)
           |> Enum.all?(fn i -> i in 1..15 end)
  end

  test "Sending one more element than exact chunk size" do
    Enum.each(1..6, &Analytics.Records.Event.record/1)
    Process.sleep(@interval_pull_in_milliseconds)

    assert Analytics.Adapter.Test.get("event")
           |> Enum.flat_map(& &1)
           |> Enum.all?(fn i -> i in 1..6 end)
  end

  test "Sending three times plus one more more element the chunk size" do
    Enum.each(1..16, &Analytics.Records.Event.record/1)
    Process.sleep(@interval_pull_in_milliseconds)

    assert Analytics.Adapter.Test.get("event")
           |> Enum.flat_map(& &1)
           |> Enum.all?(fn i -> i in 1..16 end)
  end

  test "Sending a chunk in two times" do
    Enum.each(1..3, &Analytics.Records.Event.record/1)
    Process.sleep(div(@interval_pull_in_milliseconds, 2))
    Enum.each(4..5, &Analytics.Records.Event.record/1)

    Process.sleep(@interval_pull_in_milliseconds)

    assert Analytics.Adapter.Test.get("event")
           |> Enum.flat_map(& &1)
           |> Enum.all?(fn i -> i in 1..5 end)
  end

  test "Sending a lot of events" do
    max_event = 10_000
    max_task = 5
    range = 1..max_event

    {elapsed, _result} =
      :timer.tc(fn ->
        Enum.map(1..max_task, fn _ ->
          Task.async(fn ->
            range
            |> Task.async_stream(&Analytics.Records.Event.record/1)
            |> Stream.run()
          end)
        end)
        |> Task.yield_many(10_000)
      end)

    IO.write("Records sent in #{to_human(div(elapsed, 1000))}\n")
    Process.sleep(@interval_pull_in_milliseconds * 3)

    result =
      Analytics.Adapter.Test.get("event")
      |> Enum.flat_map(& &1)

    assert length(result) == max_event * max_task
  end

  @tag :skip
  test "Sending a lot of actors" do
    max_event = 10
    max_task = 1_000
    range = 1..max_event

    {elapsed, _result} =
      :timer.tc(fn ->
        Enum.map(1..max_task, fn _ ->
          Task.async(fn ->
            range
            |> Task.async_stream(&Analytics.Records.Event.record/1)
            |> Stream.run()
          end)
        end)
        |> Task.yield_many()
      end)

    IO.write("Records sent in #{to_human(div(elapsed, 1000))}\n")
    Process.sleep(@interval_pull_in_milliseconds * 3)

    result =
      Analytics.Adapter.Test.get("event")
      |> Enum.flat_map(& &1)

    assert length(result) == max_event * max_task
  end

  defp to_human(duration, unit \\ :milliseconds)

  defp to_human(duration, :milliseconds),
    do: to_human(div(duration, 1000), :seconds) <> " #{rem(duration, 1000)}ms"

  defp to_human(0, :seconds), do: "0s"

  defp to_human(duration, :seconds),
    do: to_human(div(duration, 60), :minutes) <> " #{rem(duration, 60)}s"

  defp to_human(duration, :minutes), do: "#{duration}m"
end
