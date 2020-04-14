defmodule ByggApp.Jobs.Request do
  use Ecto.Schema
  import Ecto.Changeset

  schema "job_requests" do
    field :status, JobRequestStatusEnum, default: :pending
    belongs_to :job, ByggApp.Jobs.Job
    belongs_to :recipient, ByggApp.Accounts.User

    timestamps()
  end
end
