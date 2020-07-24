defmodule RecakeWeb.LayoutView do
  use RecakeWeb, :view

  import Phoenix.HTML

  def nav_link(conn, label, opts) do
    current_page? = opts[:to] == conn.request_path

    classes = class_list([
      {"py-2 px-4 text-gray-100 border-b-4 border-transparent hover:no-underline", true},
      {"border-blue-500", current_page?},
      {"hover:border-orange-600", !current_page?}
    ])

    opts = Keyword.put(opts, :class, classes)
    ~E"""
      <%= link label, opts %>
    """
  end

  def page_header(%{title: title, action: %{label: label, url: url} = action}) do
    ~E"""
    <div class="flex justify-between items-center">
      <h1 class="section-title"><%= title %></h1>
      <a href="<%= url %>" class="btn bg-white border-gray-500 hover:no-underline hover:bg-blue-100 text-blue-900 font-bold lowercase">
        <%= if action[:icon] do %>
        <i class="fas fa-<%= action.icon %> mr-1"></i>
        <% end %>
        <%= label %>
      </a>
    </div>
    """
  end
  def page_header(header) when is_binary(header) do
    ~E"""
      <h1 class="section-title"><%= header %></h1>
    """
  end

  def page_header(_), do: nil
end
