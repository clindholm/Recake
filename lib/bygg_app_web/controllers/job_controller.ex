defmodule ByggAppWeb.JobController do
  use ByggAppWeb, :controller

  alias ByggApp.Jobs
  alias ByggApp.Jobs.Job

  def index(conn, _params) do
    render(conn, "index.html", section_title: "Your jobs")
  end

  def new(conn, _params) do
    changeset = Jobs.change_job(%Job{})
    render(conn, "new.html", section_title: "Create new job", changeset: changeset)
  end

  def create(conn, %{"job" => job_params}) do
    case Jobs.publish_job(conn.assigns.current_user, job_params) do
      {:ok, _job} ->
        conn
        |> put_flash(:success, "Job published")
        |> redirect(to: Routes.job_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", section_title: "Create new job", changeset: changeset)
    end
  end
end
