defmodule Recake.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :description, :string
    field :location, :string
    field :state, :string, default: "active"
    belongs_to :user, Recake.Accounts.User
    has_many(:requests, Recake.Jobs.Request)

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:description, :location])
    |> validate_required([:description, :location, :user_id])
    |> validate_length(:description, min: 1, max: 300)
  end
end
