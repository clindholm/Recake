defmodule ByggAppWeb.JobControllerTest do
  use ByggAppWeb.ConnCase, async: true

  import ByggApp.AccountsFixtures
  import ByggApp.JobsFixtures

  alias ByggApp.Repo
  alias ByggApp.Jobs.Job

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

  describe "GET /jobs" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.job_path(conn, :index))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders success flash", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:success, "Success flash")
        |> get(Routes.job_path(conn, :index))

      response = html_response(conn, 200)
      assert response =~ "Success flash"
    end

    test "renders empty state", %{conn: conn} do
      conn = get(conn, Routes.job_path(conn, :index))
      response = html_response(conn, 200)
      assert_section_header response, gettext("Your jobs")
      assert response =~ gettext("You have no active jobs")
      assert response =~ "href=\"#{Routes.job_path(conn, :new)}\""
    end

    test "renders active user jobs", %{conn: conn, user: user} do
      active_job = job_fixture(user, %{identifier: "Active Job"})
      closed_job = job_fixture(user, %{is_closed: true, identifier: "Closed Job"})

      conn = get(conn, Routes.job_path(conn, :index))
      response = html_response(conn, 200)
      assert_section_header response, gettext("Your jobs")

      assert response =~ active_job.identifier
      refute response =~ closed_job.identifier
    end
  end

  describe "GET /jobs/new" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.job_path(conn, :new))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders job creation page", %{conn: conn} do
      conn = get(conn, Routes.job_path(conn, :new))
      response = html_response(conn, 200)
      assert_section_header response, gettext("Create new job")
      assert response =~ "<form action=\"#{Routes.job_path(conn, :create)}\""
      assert response =~ "name=\"job[identifier]\""
      assert response =~ "name=\"job[description]\""
      assert response =~ "name=\"job[location]\""
      assert response =~ "name=\"job[timespan]\""
      assert response =~ "type=\"submit\""
    end
  end

  describe "POST /jobs/new" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = post(conn, Routes.job_path(conn, :new), %{"job" => %{}})
      assert redirected_to(conn) == "/users/login"
    end

    test "creates a job", %{conn: conn, user: user} do
      post(conn, Routes.job_path(conn, :create), %{
        "job" => %{
          "identifier" => "Identifier",
          "description" => "Description",
          "location" => "Location",
          "timespan" => "Timespan",
        }
      })

      jobs = Repo.all(Job)
      user_id = user.id
      assert Enum.count(jobs) == 1
      assert %{
        description: "Description",
        location: "Location",
        timespan: "Timespan",
        user_id: ^user_id
      } = List.first(jobs)
    end

    test "renders errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.job_path(conn, :create), %{"job" => %{}})

      response = html_response(conn, 200)
      assert_section_header response, gettext("Create new job")
      assert response =~ dgettext("errors", "can't be blank")
    end
  end

end
