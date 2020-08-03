defmodule RecakeWeb.JobRequestController do
  use RecakeWeb, :controller

  alias Recake.Jobs

  def update(conn, %{"id" => id, "available" => _}) do
    resolve(
      conn,
      id,
      :available,
      &put_flash(
        &1,
        :success,
        gettext("%{company} has been notifed of your interest", company: &2)
      )
    )
  end

  def update(conn, %{"id" => id, "unavailable" => _}) do
    resolve(
      conn,
      id,
      :unavailable,
      &put_flash(
        &1,
        :info,
        gettext("%{company} has been notifed of your lack of interest", company: &2)
      )
    )
  end

  def update(conn, _) do
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
