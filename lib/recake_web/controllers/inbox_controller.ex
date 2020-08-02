defmodule RecakeWeb.InboxController do
  use RecakeWeb, :controller

  alias Recake.Jobs

  def index(conn, _params) do
    job_requests = Jobs.list_user_job_requests(conn.assigns.current_user) # rename incoming_requests

    jobs =
      conn.assigns.current_user
      |> Jobs.list_user_jobs()
      |> Enum.map(&transform_recruits/1)

    render(conn, "index.html", job_requests: job_requests, jobs: jobs)
  end

  defp transform_recruits(job) do
    empty_segment = %{recruits: [], total: 0, percent: 0}

    total = Enum.count(job.requests)

    requests =
      job.requests
      |> Enum.group_by(fn r -> r.state end)
      |> Enum.map(fn {k, v} ->
        segment_total = Enum.count(v)
        percent =
          round(segment_total / total * 100)

        {k, %{recruits: v, total: segment_total, percent: percent}}
      end)
      |> Enum.into(%{"available" => empty_segment, "unavailable" => empty_segment, "pending" => empty_segment})

    %{ job | requests: Map.put(requests, :total, total) }
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
