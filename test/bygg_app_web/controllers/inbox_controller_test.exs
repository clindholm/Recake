defmodule RecakeWeb.InboxControllerTest do
  use RecakeWeb.ConnCase, async: true

  import Recake.AccountsFixtures
  import Recake.JobsFixtures

  alias Recake.Repo

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
      conn = get(conn, Routes.inbox_path(conn, :index))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders flash", %{conn: conn} do
      assert_render_flash(conn, & get(&1, Routes.inbox_path(conn, :index)), :success)
      assert_render_flash(conn, & get(&1, Routes.inbox_path(conn, :index)), :info)
    end

    test "renders empty state", %{conn: conn} do
      conn
      |> get(Routes.inbox_path(conn, :index))
      |> html_document()
      |> assert_section_header(gettext("Current requests"))
      |> assert_selector_content("h2", gettext("You have no requests at this time"))
    end

    test "lists current pending requests of the user", %{conn: conn, user: user} do
      job1 = job_fixture(user)
      job2 = job_fixture(user)
      job3 = job_fixture(user)
      pending_request1 = job_request_fixture(user, job1)
      _pending_request2 = job_request_fixture(user, job2, "accepted")
      _pending_request3 = job_request_fixture(user, job3, "rejected")
      pending_request1 = Repo.preload(pending_request1, [job: [:user]])

      conn = get(conn, Routes.inbox_path(conn, :index))

      assert [^pending_request1] = conn.assigns.job_requests

      conn
      |> html_document()
      |> assert_selector_content("h3", pending_request1.job.user.company)
      |> assert_form(Routes.inbox_path(conn, :resolve, pending_request1), [
        "button[name=\"accept\"]",
        "button[name=\"reject\"]",
      ])
    end
  end

  # describe "POST /requests/:id/resolve" do
  #   setup %{conn: conn, user: user} do
  #     job_creator = user_fixture()
  #     job = job_fixture(job_creator)
  #     request = job_request_fixture(user, job)

  #     %{
  #       conn: conn,
  #       user: user,
  #       job_creator: job_creator,
  #       job: job,
  #       request: request
  #     }
  #   end

  #   test "redirects if user is not logged in" do
  #     conn = build_conn()
  #     conn = post(conn, Routes.inbox_path(conn, :resolve, 1))
  #     assert redirected_to(conn) == "/users/login"
  #   end

  #   test "resolves acceptances", %{conn: conn, request: request, job_creator: job_creator} do
  #     conn = post(conn, Routes.inbox_path(conn, :resolve, request.id), %{"accept" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     assert get_flash(conn, :success) == gettext("%{company} has been notifed of your interest", company: job_creator.company)

  #     conn
  #     |> get(Routes.inbox_path(conn, :index))
  #     |> assert_selector_times(".card-grid .card", 0)
  #   end

  #   test "resolves rejections", %{conn: conn, request: request, job_creator: job_creator} do
  #     conn = post(conn, Routes.inbox_path(conn, :resolve, request.id), %{"reject" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     assert get_flash(conn, :info) == gettext("%{company} has been notifed of your lack of interest", company: job_creator.company)

  #     conn
  #     |> get(Routes.inbox_path(conn, :index))
  #     |> assert_selector_times(".card-grid .card", 0)
  #   end

  #   test "does not resolve other user's requests", %{conn: conn, job: job} do
  #     other_user = user_fixture()
  #     request = job_request_fixture(other_user, job)

  #     conn = post(conn, Routes.inbox_path(conn, :resolve, request.id), %{"accept" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :success)

  #     assert Repo.get!(Recake.Jobs.Request, request.id).state == "pending"

  #     conn = post(conn, Routes.inbox_path(conn, :resolve, request.id), %{"reject" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :info)

  #     assert Repo.get!(Recake.Jobs.Request, request.id).state == "pending"
  #   end

  #   test "does nothing to already accepted requests", %{conn: conn, request: request} do
  #     accepted_request =
  #       request
  #       |> Ecto.Changeset.change(state: "accepted")
  #       |> Repo.update!()

  #     conn = post(conn, Routes.inbox_path(conn, :resolve, accepted_request.id), %{"accept" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :success)
  #     refute get_flash(conn, :info)

  #     assert Repo.get!(Recake.Jobs.Request, accepted_request.id).state == "accepted"

  #     conn = post(conn, Routes.inbox_path(conn, :resolve, accepted_request.id), %{"reject" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :success)
  #     refute get_flash(conn, :info)

  #     assert Repo.get!(Recake.Jobs.Request, accepted_request.id).state == "accepted"
  #   end

  #   test "does nothing to already rejected requests", %{conn: conn, request: request} do
  #     rejected_request =
  #       request
  #       |> Ecto.Changeset.change(state: "rejected")
  #       |> Repo.update!()

  #     conn = post(conn, Routes.inbox_path(conn, :resolve, rejected_request.id), %{"accept" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :success)
  #     refute get_flash(conn, :info)

  #     assert Repo.get!(Recake.Jobs.Request, rejected_request.id).state == "rejected"

  #     conn = post(conn, Routes.inbox_path(conn, :resolve, rejected_request.id), %{"reject" => ""})
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :success)
  #     refute get_flash(conn, :info)

  #     assert Repo.get!(Recake.Jobs.Request, rejected_request.id).state == "rejected"
  #   end

  #   test "does nothing on invalid resolution", %{conn: conn, request: request} do
  #     conn = post(conn, Routes.inbox_path(conn, :resolve, request.id))
  #     assert redirected_to(conn) == Routes.inbox_path(conn, :index)
  #     refute get_flash(conn, :success)
  #     refute get_flash(conn, :info)

  #     assert Repo.get!(Recake.Jobs.Request, request.id).state == "pending"
  #   end
  # end
end
