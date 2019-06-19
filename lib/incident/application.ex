defmodule Incident.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {event_store_adapter(), event_store_options()},
      {projection_store_adapter(), projection_store_options()}
    ]

    opts = [strategy: :one_for_one, name: Incident.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec event_store_adapter :: module | no_return
  defp event_store_adapter do
    event_store_config()[:adapter] || raise "An Event Store adapter is required in the config."
  end

  @spec event_store_options :: keyword
  defp event_store_options do
    event_store_config()[:options] || []
  end

  @spec projection_store_adapter :: module | no_return
  defp projection_store_adapter do
    projection_store_config()[:adapter] ||
      raise "A Projection Store adapter is required in the config."
  end

  @spec projection_store_options :: keyword
  defp projection_store_options do
    projection_store_config()[:options] || []
  end

  @spec event_store_config :: keyword
  defp event_store_config do
    Application.get_env(:incident, :event_store)
  end

  @spec projection_store_config :: keyword
  defp projection_store_config do
    Application.get_env(:incident, :projection_store)
  end
end
