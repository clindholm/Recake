defmodule RecakeWeb.JobRequestController do
  use RecakeWeb, :controller

  alias Recake.Jobs

  def update(conn, %{"id" => id, "available" => _} = props) do
    recruit_count =
      if Map.has_key?(props, "recruit_count") do
        case Integer.parse(Map.get(props, "recruit_count")) do
          {integer, _} -> integer
          _ -> 1
        end
      else
        1
      end

    resolve(
      conn,
      id,
      :available,
      recruit_count,
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
      1,
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

  defp resolve(conn, request_id, action, recruit_count, flash_f) do
    request = Jobs.get_job_request(request_id)

    if request.recipient_id == conn.assigns.current_user.id && request.state == "pending" do
      case Jobs.resolve_request(request, action, recruit_count) do
        {:ok, _} ->
          conn
          |> flash_f.(request.job.user.company)
          |> redirect(to: Routes.inbox_path(conn, :index))

        {:error, :recruit_count_exceeded} ->
          conn
          |> put_flash(:error, gettext("Your number of available recruits can't exceed the number requested"))
          |> redirect(to: Routes.inbox_path(conn, :index))

      end

    else
      redirect(conn, to: Routes.inbox_path(conn, :index))
    end
  end
end
