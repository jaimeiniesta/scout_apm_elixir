if Code.ensure_loaded?(Telemetry) do
  defmodule ScoutApm.Instruments.EctoTelemetry do
    @doc """
    Attaches an event handler for Ecto queries.

    Takes a fully namespaced Ecto.Repo module as the only argument. Example:

        ScoutApm.Instruments.EctoTelemetry.attach(MyApp.Repo)
    """
    def attach(repo_module) do
      query_event =
        repo_module
        |> Module.split()
        |> Enum.map(&(&1 |> Macro.underscore() |> String.to_atom()))
        |> Kernel.++([:query])

      Telemetry.attach(
        "scout-ecto-query-handler",
        query_event,
        ScoutApm.Instruments.EctoTelemetry,
        :handle_event,
        nil
      )
    end

    def handle_event([_app, _repo, :query], _value, metadata, _config) do
      IO.inspect "HELLO THIS IS MITCHELL"
      ScoutApm.Instruments.EctoLogger.record(metadata)
    end
  end
end
