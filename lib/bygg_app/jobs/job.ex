defmodule ByggApp.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :identifier, :string
    field :description, :string
    field :location, :string
    field :timespan, :string
    field :is_closed, :boolean, default: false
    belongs_to :user, ByggApp.Accounts.User
    has_many(:requests, ByggApp.Jobs.Request)

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:identifier, :description, :location, :timespan, :is_closed])
    |> validate_required([:identifier, :description, :location, :timespan, :is_closed, :user_id])
    |> validate_length(:identifier, min: 1, max: 40)
    |> validate_length(:description, min: 1, max: 300)
  end
end
