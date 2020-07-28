defmodule RecakeWeb.InboxController do
  use RecakeWeb, :controller

  alias Recake.Jobs

  plug :page_header, gettext("Current requests") when action in [:index]

  def index(conn, _params) do
    job_requests = Jobs.list_user_job_requests(conn.assigns.current_user)
    render(conn, "index.html", job_requests: job_requests)
  end

  def resolve(conn, %{"id" => id, "accept" => _}) do
    resolve(
      conn,
      id,
      :accept,
      &put_flash(
        &1,
        :success,
        gettext("%{company} has been notifed of your interest", company: &2)
      )
    )
  end

  def resolve(conn, %{"id" => id, "reject" => _}) do
    resolve(
      conn,
      id,
      :reject,
      &put_flash(
        &1,
        :info,
        gettext("%{company} has been notifed of your lack of interest", company: &2)
      )
    )
  end

  def resolve(conn, _) do
    redirect(conn, to: Routes.inbox_path(conn, :index))
  end

  defp resolve(conn, request_id, action, flash_f) do
    request = Jobs.get_job_request(request_id)

    if request.recipient_id == conn.assigns.current_user.id && request.state == "pending" do
      Jobs.resolve_request(request, action)

      conn
      |> flash_f.(request.job.user.company)
      |> redirect(to: Routes.inbox_path(conn, :index))
    else
      redirect(conn, to: Routes.inbox_path(conn, :index))
    end
  end
end
