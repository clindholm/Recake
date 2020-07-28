defmodule RecakeWeb.InboxView do
  use RecakeWeb, :view

  import Phoenix.HTML

  def filter_requests(requests, state) when is_atom(state) do
    requests
    |> Enum.filter(& &1.state == state)
  end
  def filter_requests(requests, states) when is_list(states) do
    requests
    |> Enum.filter(& &1.state in states)
  end

  def request_status_badge(request) do
    {text, colors} =
      case request.state do
        :pending -> {"pending", "bg-blue-200 text-blue-900"}
        :rejected -> {"declined", "bg-red-200 text-red-900"}

      end

    classes = "rounded text-sm px-2 mr-3 #{colors}"

    ~E"""
      <span class="<%= classes %>"><%= text %></span>
    """
  end
end
