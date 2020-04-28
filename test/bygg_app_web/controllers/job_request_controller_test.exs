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

  describe "GET /" do
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

    test "renders info flash", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:info, "Info flash")
        |> get(Routes.job_request_path(conn, :index))

      response = html_response(conn, 200)
      assert response =~ "Info flash"
    end

    test "renders empty state", %{conn: conn} do
      conn = get(conn, Routes.job_request_path(conn, :index))
      response = html_response(conn, 200)
      assert_section_header response, gettext("Current requests")
      assert response =~ gettext("You have no requests at this time")
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
      assert response =~ Routes.job_request_path(conn, :resolve, pending_request1)
      assert response =~ "name=\"accept\""
      assert response =~ "name=\"reject\""
      assert response =~ Routes.job_request_path(conn, :resolve, pending_request1)
    end
  end

  describe "POST /requests/:id/resolve" do
    setup %{conn: conn, user: user} do
      job_creator = user_fixture()
      job = job_fixture(job_creator)
      request = job_request_fixture(user, job)

      %{
        conn: conn,
        user: user,
        job_creator: job_creator,
        job: job,
        request: request
      }
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = post(conn, Routes.job_request_path(conn, :resolve, 1))
      assert redirected_to(conn) == "/users/login"
    end

    test "resolves acceptances", %{conn: conn, request: request, job_creator: job_creator} do
      conn = post(conn, Routes.job_request_path(conn, :resolve, request.id), %{"accept" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      assert get_flash(conn, :success) == gettext("%{company} has been notifed of your interest", company: job_creator.company)

      conn = get(conn, Routes.job_request_path(conn, :index))
      response = html_response(conn, 200)
      refute response =~ Routes.job_request_path(conn, :resolve, request.id)
    end

    test "resolves rejections", %{conn: conn, request: request, job_creator: job_creator} do
      conn = post(conn, Routes.job_request_path(conn, :resolve, request.id), %{"reject" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      assert get_flash(conn, :info) == gettext("%{company} has been notifed of your lack of interest", company: job_creator.company)

      conn = get(conn, Routes.job_request_path(conn, :index))
      response = html_response(conn, 200)
      refute response =~ Routes.job_request_path(conn, :resolve, request.id)
    end

    test "does not resolve other user's requests", %{conn: conn, job: job} do
      other_user = user_fixture()
      request = job_request_fixture(other_user, job)

      conn = post(conn, Routes.job_request_path(conn, :resolve, request.id), %{"accept" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :success)

      assert Repo.get!(ByggApp.Jobs.Request, request.id).status == :pending

      conn = post(conn, Routes.job_request_path(conn, :resolve, request.id), %{"reject" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :info)

      assert Repo.get!(ByggApp.Jobs.Request, request.id).status == :pending
    end

    test "does nothing to already accepted requests", %{conn: conn, request: request} do
      accepted_request =
        request
        |> Ecto.Changeset.change(status: :accepted)
        |> Repo.update!()

      conn = post(conn, Routes.job_request_path(conn, :resolve, accepted_request.id), %{"accept" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(ByggApp.Jobs.Request, accepted_request.id).status == :accepted

      conn = post(conn, Routes.job_request_path(conn, :resolve, accepted_request.id), %{"reject" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(ByggApp.Jobs.Request, accepted_request.id).status == :accepted
    end

    test "does nothing to already rejected requests", %{conn: conn, request: request} do
      rejected_request =
        request
        |> Ecto.Changeset.change(status: :rejected)
        |> Repo.update!()

      conn = post(conn, Routes.job_request_path(conn, :resolve, rejected_request.id), %{"accept" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(ByggApp.Jobs.Request, rejected_request.id).status == :rejected

      conn = post(conn, Routes.job_request_path(conn, :resolve, rejected_request.id), %{"reject" => ""})
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(ByggApp.Jobs.Request, rejected_request.id).status == :rejected
    end

    test "does nothing on invalid resolution", %{conn: conn, request: request} do
      conn = post(conn, Routes.job_request_path(conn, :resolve, request.id))
      assert redirected_to(conn) == Routes.job_request_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(ByggApp.Jobs.Request, request.id).status == :pending
    end
  end
end
