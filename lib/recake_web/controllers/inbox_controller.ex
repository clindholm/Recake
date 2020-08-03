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
end
