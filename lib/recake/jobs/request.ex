defmodule Recake.Jobs.Request do
  use Ecto.Schema

  schema "job_requests" do
    field :state, :string, default: "pending" # pending, available, unavailable
    belongs_to :job, Recake.Jobs.Job
    belongs_to :recipient, Recake.Accounts.User

    timestamps()
  end
end
