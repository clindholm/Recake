defmodule ByggApp.Jobs.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :description, :string
    field :location, :string
    field :timespan, :string
    field :status, JobStatusEnum, default: :published
    belongs_to :user, ByggApp.Accounts.User

    timestamps()
  end

  def changeset(job, attrs) do
    job
    |> cast(attrs, [:description, :location, :timespan, :status])
    |> validate_required([:description, :location, :timespan, :status, :user_id])
    |> validate_length(:description, max: 300)
  end
end
