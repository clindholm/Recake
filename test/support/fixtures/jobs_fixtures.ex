defmodule ByggApp.JobsFixtures do
  alias ByggApp.Repo
  alias ByggApp.Jobs.Job
  alias ByggApp.Accounts.User

  def job_fixture(%User{} = user, attrs \\ %{}) do
    %Job{
      user_id: user.id,
      description: Map.get(attrs, :description, "Job description"),
      location: Map.get(attrs, :location, "Job location"),
      timespan: Map.get(attrs, :timespan, "Timespan")
    }
    |> Repo.insert!()
  end
end
