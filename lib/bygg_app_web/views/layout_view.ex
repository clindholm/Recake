defmodule ByggAppWeb.LayoutView do
  use ByggAppWeb, :view

  import Phoenix.HTML

  def nav_link(conn, label, opts) do
    current_page? = opts[:to] == conn.request_path

    classes = class_list([
      {"mr-4 py-2 px-4 text-gray-100 rounded-lg hover:no-underline", true},
      {"bg-gray-900", current_page?},
      {"hover:bg-blue-800", !current_page?}
    ])

    opts = Keyword.put(opts, :class, classes)
    ~E"""
      <%= link label, opts %>
    """
  end
end
