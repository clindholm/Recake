defmodule ByggApp.JobsFixtures do
  alias ByggApp.Repo
  alias ByggApp.Jobs.Job
  alias ByggApp.Accounts.User

  def job_fixture(%User{} = user, attrs \\ %{}) do
    %Job{
      user_id: user.id
    }
    |> Ecto.Changeset.change(Enum.into(attrs, %{
      description: "Job description",
      location: "Job location",
      timespan: "Timespan"
    }))
    |> Repo.insert!()
  end
end
