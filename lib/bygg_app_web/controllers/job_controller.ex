defmodule ByggAppWeb.JobController do
  use ByggAppWeb, :controller

  alias ByggApp.Jobs
  alias ByggApp.Jobs.Job

  plug :section_title, gettext("Your jobs") when action in [:index]
  plug :section_title, gettext("Create new job") when action in [:new, :create]

  def index(conn, _params) do
    jobs = Jobs.list_user_jobs(conn.assigns.current_user)
    render(conn, "index.html", jobs: jobs)
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
end
