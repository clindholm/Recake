defmodule ByggAppWeb.LayoutView do
  use ByggAppWeb, :view

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
end
