defmodule Recake.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :description, :string
    field :location, :string
    field :internal_id, :string
    field :id06_required, :boolean, default: false
    field :state, :string, default: "active"
    belongs_to :user, Recake.Accounts.User
    has_many(:requests, Recake.Jobs.Request)

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:description, :location, :internal_id, :id06_required])
    |> validate_required([:description, :location, :internal_id, :id06_required, :user_id])
    |> validate_length(:description, min: 1, max: 300)
    |> validate_length(:internal_id, min: 1, max: 30)
  end
end
