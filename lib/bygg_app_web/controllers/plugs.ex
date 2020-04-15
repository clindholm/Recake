defmodule ByggAppWeb.Plugs do
  def section_title(conn, title) do
    Plug.Conn.assign(conn, :section_title, title)
  end
end
