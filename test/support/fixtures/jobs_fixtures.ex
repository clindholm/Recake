defmodule Recake.JobsFixtures do
  alias Recake.Repo
  alias Recake.Jobs.{Job, Request}
  alias Recake.Accounts.User

  def job_fixture(%User{} = user, attrs \\ %{}) do
    %Job{
      user_id: user.id
    }
    |> Ecto.Changeset.change(Enum.into(attrs, %{
      description: "Job description",
      location: "Job location",
      internal_id: "Internal Id",
      id06_required: false
    }))
    |> Repo.insert!()
  end

  def job_request_fixture(%User{} = user, %Job{} = job, state \\ "pending") do
    %Request{
      job_id: job.id,
      recipient_id: user.id,
      state: state
    }
    |> Repo.insert!()
  end
end
