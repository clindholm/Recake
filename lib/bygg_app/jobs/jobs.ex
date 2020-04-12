defmodule ByggApp.Jobs do
  alias ByggApp.Repo

  alias ByggApp.Accounts.User

  alias ByggApp.Jobs.Job


  def get_job(id), do: Repo.get(Job, id)

  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end

  def publish_job(%User{} = user, attrs) do
    %Job{ user_id: user.id }
    |> Job.changeset(attrs)
    |> Repo.insert()
  end
end
