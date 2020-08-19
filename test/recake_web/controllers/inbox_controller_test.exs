defmodule RecakeWeb.InboxControllerTest do
  use RecakeWeb.ConnCase, async: true

  import Recake.AccountsFixtures
  import Recake.JobsFixtures

  alias Recake.Repo

  setup %{conn: conn} do
    user = user_fixture()

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
      assert_render_flash(conn, &get(&1, Routes.inbox_path(conn, :index)), :success)
      assert_render_flash(conn, &get(&1, Routes.inbox_path(conn, :index)), :info)
    end

    test "renders empty state", %{conn: conn} do
      conn
      |> get(Routes.inbox_path(conn, :index))
      |> html_document()
      |> assert_selector_content("h2", gettext("empty inbox"))
      |> assert_selector_content("h2", gettext("empty recruitments"))
    end

    test "lists current pending requests of the user", %{conn: conn, user: user} do
      job1 = job_fixture(user)
      job2 = job_fixture(user)
      job3 = job_fixture(user)
      pending_request1 = job_request_fixture(user, job1)
      _pending_request2 = job_request_fixture(user, job2, "available")
      _pending_request3 = job_request_fixture(user, job3, "unavailable")
      pending_request1 = Repo.preload(pending_request1, job: [:user])

      conn = get(conn, Routes.inbox_path(conn, :index))

      assert [^pending_request1] = conn.assigns.incoming_requests

      conn
      |> html_document()
      |> assert_selector_content("h3", pending_request1.job.user.company)
      |> assert_form(Routes.job_request_path(conn, :update, pending_request1), [
        "button[name=\"available\"]",
        "button[name=\"unavailable\"]"
      ])
    end

    test "renders recruit count input for jobs that need more than one", %{conn: conn, user: user} do
      job1 = job_fixture(user, %{ recruit_count: 1 })
      job2 = job_fixture(user, %{ recruit_count: 3 })

      request1 = job_request_fixture(user, job1)
      request2 = job_request_fixture(user, job2)

      conn
      |> get(Routes.inbox_path(conn, :index))
      |> html_document()
      |> refute_selector("#req-#{request1.id} input[name=\"recruit_count\"]")
      |> assert_selector("#req-#{request2.id} input[name=\"recruit_count\"]")
    end

    test "renders ID06 requirements", %{conn: conn, user: user} do
      job1 = job_fixture(user)
      job2 = job_fixture(user, %{ id06_required: true })
      _pending_request1 = job_request_fixture(user, job1)
      _pending_request2 = job_request_fixture(user, job2)

      conn = get(conn, Routes.inbox_path(conn, :index))

      conn
      |> html_document()
      |> assert_selector_times(".id06-warning", 1)
    end

    test "transforms job requests", %{conn: conn, user: user} do
      active_job = job_fixture(user)

      [pending_recruit, available_recruit1, available_recruit2, unavailable_recruit] =
        create_recruits_for_job(active_job, ["pending", "available", "available", "unavailable"])

      conn =
        conn
        |> get(Routes.inbox_path(conn, :index))

      job =
        conn.assigns.jobs
        |> List.first()

      assert job.requests.statistics.total == 4
      assert job.requests.statistics.available.total == 2
      assert job.requests.statistics.available.percent == 50
      assert job.requests.statistics.unavailable.total == 1
      assert job.requests.statistics.unavailable.percent == 25
      assert job.requests.statistics.pending.total == 1
      assert job.requests.statistics.pending.percent == 25

      assert job.requests.available == [available_recruit1, available_recruit2]
      assert job.requests.hidden == [pending_recruit, unavailable_recruit]
    end

    test "renders active user jobs and recruits", %{conn: conn, user: user} do
      active_job = job_fixture(user)
      closed_job = job_fixture(user, %{state: "closed"})

      [pending_recruit, available_recruit, unavailable_recruit] =
        create_recruits_for_job(active_job, ["pending", "available", "unavailable"])

      conn
      |> get(Routes.inbox_path(conn, :index))
      |> html_document()
      |> assert_selector("a[href=\"#{Routes.job_path(conn, :edit, active_job.id)}\"]")
      |> refute_selector("a[href=\"#{Routes.job_path(conn, :edit, closed_job.id)}\"]")
      |> assert_selector_content(".job .active-recruits", available_recruit.recipient.company)
      |> assert_selector_content(".job .inactive-recruits", pending_recruit.recipient.company)
      |> assert_selector_content(".job .inactive-recruits", unavailable_recruit.recipient.company)
    end
  end

  defp create_recruits_for_job(job, statuses) do
    for status <- statuses do
      recruit = user_fixture(%{company: "Company #{status}"})

      job_request_fixture(recruit, job, status)
      |> Repo.preload(:recipient)
    end
  end
end
