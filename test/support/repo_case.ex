defmodule Incident.RepoCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox
  alias Ecto.Changeset
  alias Incident.EventStore.TestRepo, as: EventStoreTestRepo
  alias Incident.ProjectionStore.TestRepo, as: ProjectionStoreTestRepo

  using do
    quote do
      import Incident.RepoCase
    end
  end

  setup tags do
    :ok = Sandbox.checkout(EventStoreTestRepo)
    :ok = Sandbox.checkout(ProjectionStoreTestRepo)

    unless tags[:async] do
      Sandbox.mode(EventStoreTestRepo, {:shared, self()})
      Sandbox.mode(ProjectionStoreTestRepo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transform changeset errors to a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
