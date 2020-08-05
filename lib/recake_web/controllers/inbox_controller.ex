defmodule RecakeWeb.InboxController do
  use RecakeWeb, :controller

  alias Recake.Jobs

  def index(conn, _params) do
    # rename incoming_requests
    incoming_requests = Jobs.list_user_incoming_requests(conn.assigns.current_user)

    jobs =
      conn.assigns.current_user
      |> Jobs.list_user_jobs()
      |> Enum.map(&transform_recruits/1)

    render(conn, "index.html", incoming_requests: incoming_requests, jobs: jobs)
  end

  defp transform_recruits(job) do
    init = %{
      statistics: %{
        total: 0,
        available: %{
          total: 0,
          percent: 0
        },
        unavailable: %{
          total: 0,
          percent: 0
        },
        pending: %{
          total: 0,
          percent: 0
        }
      },
      available: [],
      hidden: []
    }

    requests =
      job.requests
      |> Enum.reduce(init, fn request, acc ->
        cond do
          request.state == "available" ->
            append_request_to(acc, request, :available, :available)

          request.state == "unavailable" ->
            append_request_to(acc, request, :hidden, :unavailable)

          request.state == "pending" ->
            append_request_to(acc, request, :hidden, :pending)
        end
        |> update_in([:statistics, :total], &(&1 + 1))
      end)
      |> (fn rs ->
            Enum.reduce([:available, :unavailable, :pending], rs, fn category, acc ->
              put_in(
                acc,
                [:statistics, category, :percent],
                round(get_in(acc, [:statistics, category, :total]) / acc.statistics.total * 100)
              )
            end)
          end).()
      |> (fn rs ->
            rs
            |> update_in([:available], &Enum.reverse/1)
            |> update_in([:hidden], &Enum.reverse/1)
          end).()

    %{job | requests: requests}
  end

  defp append_request_to(acc, request, group, stats_key) do
    acc
    |> update_in([group], &[request | &1])
    |> update_in([:statistics, stats_key, :total], &(&1 + 1))
  end
end
