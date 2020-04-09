defmodule ByggAppWeb.PageController do
  use ByggAppWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
