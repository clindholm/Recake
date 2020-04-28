defmodule ByggAppWeb.JobView do
  use ByggAppWeb, :view

  import Phoenix.HTML

  def filter_requests(requests, status) when is_atom(status) do
    requests
    |> Enum.filter(& &1.status == status)
  end
  def filter_requests(requests, statuses) when is_list(statuses) do
    requests
    |> Enum.filter(& &1.status in statuses)
  end

  def request_status_badge(request) do
    {text, colors} =
      case request.status do
        :pending -> {"pending", "bg-blue-200 text-blue-900"}
        :rejected -> {"declined", "bg-red-200 text-red-900"}

      end

    classes = "rounded text-sm px-2 mr-3 #{colors}"

    ~E"""
      <span class="<%= classes %>"><%= text %></span>
    """
  end
end
