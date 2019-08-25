defmodule Incident.EventStore.PostgresEvent do
  @moduledoc """
  Defines the data structure for any event for the Postgres adapter.

  All fields are required.
  """

  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          aggregate_id: String.t() | nil,
          event_type: String.t() | nil,
          version: pos_integer | nil,
          event_date: DateTime.t() | nil,
          event_data: map | nil
        }

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "events" do
    field(:event_id, :string)
    field(:aggregate_id, :string)
    field(:event_type, :string)
    field(:version, :integer)
    field(:event_date, :utc_datetime)
    field(:event_data, :map)
  end

  @required_fields ~w(event_id aggregate_id event_type version event_date event_data)a

  @doc false
  @spec changeset(t, map) :: Ecto.Changeset.t()
  def changeset(record, params \\ %{}) do
    record
    |> cast(params, @required_fields)
    |> validate_required(@required_fields)
    |> validate_number(:version, greater_than: 0)
  end
end
