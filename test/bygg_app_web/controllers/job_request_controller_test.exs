defmodule ByggAppWeb.JobRequestControllerTest do
  use ByggAppWeb.ConnCase, async: true

  import ByggApp.AccountsFixtures
  import ByggApp.JobsFixtures

  alias ByggApp.Repo

  setup %{conn: conn} do
    user =
      user_fixture()

    conn =
      conn
      |> login_user(user)

    %{
      conn: conn,
      user: user
    }
  end

  describe "GET /requests" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.job_request_path(conn, :index))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders success flash", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:success, "Success flash")
        |> get(Routes.job_request_path(conn, :index))

      response = html_response(conn, 200)
      assert response =~ "Success flash"
    end

    test "renders empty state", %{conn: conn} do
      conn = get(conn, Routes.job_request_path(conn, :index))
      response = html_response(conn, 200)
      assert_section_header response, "Current requests"
      assert response =~ "You have no requests at this time"
    end

    test "lists current pending requests of the user", %{conn: conn, user: user} do
      job1 = job_fixture(user)
      job2 = job_fixture(user)
      job3 = job_fixture(user)
      pending_request1 = job_request_fixture(user, job1)
      _pending_request2 = job_request_fixture(user, job2, :accepted)
      _pending_request3 = job_request_fixture(user, job3, :rejected)
      pending_request1 = Repo.preload(pending_request1, [job: [:user]])

      conn = get(conn, Routes.job_request_path(conn, :index))

      assert [^pending_request1] = conn.assigns.job_requests

      response = html_response(conn, 200)

      assert response =~ pending_request1.job.user.company
    end
  end
end
