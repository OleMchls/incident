{:ok, _apps} = Application.ensure_all_started(:incident)
{:ok, _pid} = Incident.EventStore.TestRepo.start_link()
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Incident.EventStore.TestRepo, :manual)
