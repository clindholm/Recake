defmodule ByggAppWeb.JobRequestController do
  use ByggAppWeb, :controller

  alias ByggApp.Jobs

  plug :section_title, gettext("Current requests") when action in [:index]

  def index(conn, _params) do
    job_requests = Jobs.list_user_job_requests(conn.assigns.current_user)
    render(conn, "index.html", job_requests: job_requests)
  end

  def resolve(conn, %{"id" => id, "accept" => _}) do
    request = Jobs.get_job_request(id)
    if request.recipient_id == conn.assigns.current_user.id do
      Jobs.resolve_request(request, :accept)

      conn
      |> put_flash(:success, gettext("%{company} has been notifed of your interest", company: request.job.user.company))
      |> redirect(to: Routes.job_request_path(conn, :index))
    else
      redirect(conn, to: Routes.job_request_path(conn, :index))
    end
  end
  def resolve(conn, %{"id" => id, "reject" => _}) do
    request = Jobs.get_job_request(id)
    if request.recipient_id == conn.assigns.current_user.id do
      Jobs.resolve_request(request, :reject)

      conn
      |> put_flash(:info, gettext("%{company} has been notifed of your lack of interest", company: request.job.user.company))
      |> redirect(to: Routes.job_request_path(conn, :index))
    else
      redirect(conn, to: Routes.job_request_path(conn, :index))
    end
  end
end
