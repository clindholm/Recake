defmodule RecakeWeb.JobController do
  use RecakeWeb, :controller

  alias Recake.Jobs
  alias Recake.Jobs.Job

  plug :page_header, gettext("Create new job") when action in [:new, :create]
  plug :page_header, gettext("Edit job") when action in [:edit, :update]

  plug :authorize_job_edit when action in [:edit, :update]

  def index(conn, _params) do
    jobs = Jobs.list_user_jobs(conn.assigns.current_user)

    conn
    |> assign(:page_header, %{
      title: gettext("Your jobs"),
      action: %{label: gettext("Create new job"), url: Routes.job_path(conn, :new), icon: "plus-circle"}
    })
    |> render("index.html", jobs: jobs)
  end

  def new(conn, _params) do
    changeset = Jobs.change_job(%Job{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"job" => job_params}) do
    case Jobs.publish_job(conn.assigns.current_user, job_params) do
      {:ok, _job} ->
        conn
        |> put_flash(:success, gettext("Job created"))
        |> redirect(to: Routes.job_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, _) do
    render(conn, "edit.html")
  end

  def update(conn, %{"job" => job_params}) do
    case Jobs.update_job(conn.assigns.job, job_params) do
      {:ok, job} ->
        conn
        |> put_flash(:success, gettext("'%{project_id}' was updated", project_id: job.identifier))
        |> redirect(to: Routes.job_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp authorize_job_edit(conn, _params) do
    %{params: %{"id" => job_id}} = conn

    job = Jobs.get_job(job_id)

    if job && conn.assigns.current_user.id == job.user_id do
      conn
      |> assign(:job, job)
      |> assign(:changeset, Jobs.change_job(job))
    else
      conn
      |> redirect(to: Routes.job_path(conn, :index))
      |> halt()
    end
  end
end
