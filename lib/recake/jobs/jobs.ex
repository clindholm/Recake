defmodule Recake.Jobs do
  import Ecto.Query, only: [from: 2]

  alias Recake.Repo
  alias Recake.Accounts.User
  alias Recake.Jobs.{Job, Request}

  def get_job(id), do: Repo.get(Job, id)

  def get_job_request(id) do
    from(r in Request,
      where: r.id == ^id,
      preload: [job: :user]
    )
    |> Repo.one()
  end

  def list_user_jobs(user) do
    from(j in Job,
      where: j.user_id == ^user.id and j.state == ^"active",
      preload: [requests: :recipient]
    )
    |> Repo.all()
  end

  def list_user_incoming_requests(user) do
    from(r in Request,
      where: r.recipient_id == ^user.id and r.state == ^"pending",
      preload: [job: :user]
    )
    |> Repo.all()
  end

  def change_job(%Job{} = job, attrs \\ %{}) do
    Job.changeset(job, attrs)
  end

  def publish_job(%User{} = user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:job, Job.changeset(%Job{user_id: user.id}, attrs))
    |> Ecto.Multi.run(:requests, fn repo, %{job: job} ->
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      recipients =
        from(u in User,
          where: u.id != ^user.id,
          select: u.id
        )
        |> repo.all()
        |> Enum.map(&%{recipient_id: &1, job_id: job.id, inserted_at: now, updated_at: now})

      result = repo.insert_all(Request, recipients)
      {:ok, result}
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{job: job}} -> {:ok, job}
      {:error, :job, changeset, _} -> {:error, changeset}
    end
  end

  def update_job(job, attrs) do
    job
    |> change_job(attrs)
    |> Repo.update()
  end

  def resolve_request(request, :available) do
    request
    |> Ecto.Changeset.change(state: "available")
    |> Repo.update()
  end

  def resolve_request(request, :unavailable) do
    request
    |> Ecto.Changeset.change(state: "unavailable")
    |> Repo.update()
  end

  def resolve_request(_request, _state), do: {:error, :invalid_resolution}
end
