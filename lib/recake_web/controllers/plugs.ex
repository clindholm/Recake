defmodule RecakeWeb.Plugs do
  def page_header(conn, header) do
    Plug.Conn.assign(conn, :page_header, header)
  end
end
