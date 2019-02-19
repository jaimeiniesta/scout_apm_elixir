defmodule ScoutApm.Plugs.ControllerTimerTest do
  use ExUnit.Case
  use Plug.Test

  setup do
    ScoutApm.TestCollector.clear_messages()
    :ok
  end

  test "creates web trace" do
    conn(:get, "/")
    |> ScoutApm.TestPlugApp.call([])

    [%{BatchCommand: %{commands: commands}}] = ScoutApm.TestCollector.messages()

    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :StartSpan)
      map && Map.get(map, :operation) == "Controller/PageController#index"
    end)
  end

  test "includes error metric on 500 response" do
    conn(:get, "/500")
    |> ScoutApm.TestPlugApp.call([])

    [%{BatchCommand: %{commands: commands}}] = ScoutApm.TestCollector.messages()

    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :StartSpan)
      map && Map.get(map, :operation) ==  "Controller/PageController#500"
    end)
    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :TagSpan)
      map && Map.get(map, :tag) == "error" && Map.get(map, :value) == "true"
    end)
  end

  test "adds ip context" do
    conn(:get, "/")
    |> ScoutApm.TestPlugApp.call([])

    [%{BatchCommand: %{commands: commands}}] = ScoutApm.TestCollector.messages()

    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :StartSpan)
      map && Map.get(map, :operation) ==  "Controller/PageController#index"
    end)
    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :TagRequest)
      map && Map.get(map, :tag) == :ip && is_binary(Map.get(map, :value))
    end)
  end

  test "adds ip context from x-forwarded-for header" do
    conn(:get, "/x-forwarded-for")
    |> ScoutApm.TestPlugApp.call([])

    [%{BatchCommand: %{commands: commands}}] = ScoutApm.TestCollector.messages()

    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :StartSpan)
      map && Map.get(map, :operation) ==  "Controller/PageController#x-forwarded-for"
    end)
    assert Enum.any?(commands, fn(command) ->
      map = Map.get(command, :TagRequest)
      map && Map.get(map, :tag) == :ip && Map.get(map, :value) == "1.2.3.4"
    end)
  end
end
