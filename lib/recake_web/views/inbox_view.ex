defmodule RecakeWeb.InboxView do
  use RecakeWeb, :view

  import Phoenix.HTML
  import RecakeWeb.HtmlHelpers

  def request_acceptance_input(request) do
    display_recruit_count = request.job.recruit_count > 1

    classes =
      class_list([
        {"flex-1 py-2 text-green-500 border border-r-0 border-green-500 hover:bg-green-500 hover:text-white", true},
        {"rounded-l", !display_recruit_count},
      ])

    button =
      ~E"""
      <button name="available" class="<%= classes %>"><%= gettext("Show interest") %></button>
      """

    if display_recruit_count do
      ~E"""
        <div class="flex items-center bg-gray-700 rounded-l text-gray-200 text-lg px-2" data-tooltip="<%= gettext("How many recruits do you have available?") %>">
          <svg class="mr-1" aria-hidden="true" focusable="false" role="img" xmlns="http://www.w3.org/2000/svg" width="20" height="20">
            <use href="#icon-user-plus" />
          </svg>
          <input type="number" name="recruit_count" min=1 max="<%= request.job.recruit_count %>" value=1 class="w-10 px-2 bg-gray-600 text-gray-100 font-bold text-right number-input-bare">
          <p class="ml-2">/<%= request.job.recruit_count %></p>
        </div>
        <%= button %>
      """
    else
      button
    end
  end

  def filter_requests(requests, state) when is_binary(state) do
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
        "pending" -> {gettext("pending"), "bg-blue-200 text-blue-900"}
        "unavailable" -> {gettext("declined"), "bg-red-200 text-red-900"}

      end

    classes = "rounded text-sm px-2 mr-3 #{colors}"

    ~E"""
      <span class="<%= classes %>"><%= text %></span>
    """
  end
end
