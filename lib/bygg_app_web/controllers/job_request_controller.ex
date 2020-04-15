defmodule ByggAppWeb.JobRequestController do
  use ByggAppWeb, :controller

  alias ByggApp.Jobs

  plug :section_title, "Current requests" when action in [:index]

  def index(conn, _params) do
    job_requests = Jobs.list_user_job_requests(conn.assigns.current_user)
    render(conn, "index.html", job_requests: job_requests)
  end
end
