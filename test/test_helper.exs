{:ok, _pid} = Incident.EventStore.TestRepo.start_link()
{:ok, _pid} = Incident.ProjectionStore.TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(Incident.EventStore.TestRepo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Incident.ProjectionStore.TestRepo, :manual)
ExUnit.start()
