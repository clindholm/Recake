defmodule ByggAppWeb.JobControllerTest do
  use ByggAppWeb.ConnCase, async: true

  import ByggApp.AccountsFixtures
  import ByggApp.JobsFixtures

  alias ByggApp.Repo
  alias ByggApp.Jobs.Job

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

  describe "GET /jobs" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.job_path(conn, :index))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders flash", %{conn: conn} do
      assert_render_flash(conn, &get(&1, Routes.job_path(conn, :index)), :success)
    end

    test "renders empty state", %{conn: conn} do
      conn
      |> get(Routes.job_path(conn, :index))
      |> html_document()
      |> assert_section_header(gettext("Your jobs"))
      |> assert_selector_content("h2", gettext("You have no active jobs"))
      |> assert_selector("a[href=\"#{Routes.job_path(conn, :new)}\"]")
    end

    test "renders active user jobs", %{conn: conn, user: user} do
      active_job = job_fixture(user, %{identifier: "Active Job"})
      closed_job = job_fixture(user, %{is_closed: true, identifier: "Closed Job"})

      conn
      |> get(Routes.job_path(conn, :index))
      |> html_document()
      |> assert_section_header(gettext("Your jobs"))
      |> assert_selector_content(".project-id", active_job.identifier)
      |> refute_selector_content(".project-id", closed_job.identifier)
    end
  end

  describe "GET /jobs/new" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.job_path(conn, :new))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders job creation page", %{conn: conn} do
      conn
      |> get(Routes.job_path(conn, :new))
      |> html_document()
      |> assert_section_header(gettext("Create new job"))
      |> assert_form(Routes.job_path(conn, :create), [
        "input[name=\"job[identifier]\"]",
        "textarea[name=\"job[description]\"]",
        "input[name=\"job[location]\"]",
        "input[name=\"job[timespan]\"]",
        "*[type=submit]"
      ])
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
          "timespan" => "Timespan"
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
      conn
      |> post(Routes.job_path(conn, :create), %{"job" => %{}})
      |> html_document()
      |> assert_section_header(gettext("Create new job"))
      |> assert_selector_content(".validation-error", dgettext("errors", "can't be blank"))
    end
  end
end
