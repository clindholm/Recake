defmodule ByggApp.JobsFixtures do
  alias ByggApp.Repo
  alias ByggApp.Jobs.{Job, Request}
  alias ByggApp.Accounts.User

  def job_fixture(%User{} = user, attrs \\ %{}) do
    %Job{
      user_id: user.id
    }
    |> Ecto.Changeset.change(Enum.into(attrs, %{
      identifier: "ID",
      description: "Job description",
      location: "Job location",
      timespan: "Timespan"
    }))
    |> Repo.insert!()
  end

  def job_request_fixture(%User{} = user, %Job{} = job, status \\ :pending) do
    %Request{
      job_id: job.id,
      recipient_id: user.id,
      status: status
    }
    |> Repo.insert!()
  end
end
