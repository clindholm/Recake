defmodule ByggApp.Jobs do
  import Ecto.Query, only: [from: 2]

  alias ByggApp.Repo
  alias ByggApp.Accounts.User
  alias ByggApp.Jobs.{Job, Request}

  def get_job(id), do: Repo.get(Job, id)

  def get_job_request(id) do
    (from r in Request,
      where: r.id == ^id,
      preload: [job: :user])
    |> Repo.one()
  end

  def list_user_jobs(user) do
    (from j in Job,
      where: j.user_id == ^user.id and not j.is_closed)
    |> Repo.all()
  end

  def list_user_job_requests(user) do
    (from r in Request,
      where: r.recipient_id == ^user.id and r.status == ^:pending,
      preload: [job: :user])
    |> Repo.all()
  end

  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end

  def publish_job(%User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:job, Job.changeset(%Job{ user_id: user.id }, attrs))
    |> Ecto.Multi.run(:requests, fn repo, %{job: job} ->
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      recipients =
        (from u in User,
          where: u.id != ^user.id,
          select: u.id)
        |> repo.all()
        |> Enum.map(&(%{recipient_id: &1, job_id: job.id, inserted_at: now, updated_at: now}))

      result = repo.insert_all(Request, recipients)
      {:ok, result}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{job: job}} -> {:ok, job}
      {:error, :job, changeset, _} -> {:error, changeset}
    end
  end

  def resolve_request(request, :accept) do
    request
    |> Ecto.Changeset.change(status: :accepted)
    |> Repo.update()
  end

  def resolve_request(request, :reject) do
    request
    |> Ecto.Changeset.change(status: :rejected)
    |> Repo.update()
  end

  def resolve_request(_request, _status), do: {:error, :invalid_resolution}
end
