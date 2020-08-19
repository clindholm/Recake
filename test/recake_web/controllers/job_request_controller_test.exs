defmodule ByggAppWeb.JobRequestControllerTest do
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

  describe "PUT /requests/:id" do
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
      conn = put(conn, Routes.job_request_path(conn, :update, 1))
      assert redirected_to(conn) == "/users/login"
    end

    test "resolves acceptances", %{conn: conn, request: request, job_creator: job_creator} do
      conn = put(conn, Routes.job_request_path(conn, :update, request.id), %{"available" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      assert get_flash(conn, :success) == gettext("%{company} has been notifed of your interest", company: job_creator.company)

      conn
      |> get(Routes.inbox_path(conn, :index))
      |> assert_selector_times(".card-grid .card", 0)

      assert Repo.get!(Recake.Jobs.Request, request.id).state == "available"
    end

    test "resolves rejections", %{conn: conn, request: request, job_creator: job_creator} do
      conn = put(conn, Routes.job_request_path(conn, :update, request.id), %{"unavailable" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      assert get_flash(conn, :info) == gettext("%{company} has been notifed of your lack of interest", company: job_creator.company)

      conn
      |> get(Routes.inbox_path(conn, :index))
      |> assert_selector_times(".card-grid .card", 0)

      assert Repo.get!(Recake.Jobs.Request, request.id).state == "unavailable"
    end

    test "registers recruit count", %{conn: conn, request: request, job: job} do
      Repo.update!(Ecto.Changeset.change(job, recruit_count: 3))

      put(conn, Routes.job_request_path(conn, :update, request.id), %{"available" => "", "recruit_count" => "3"})

      assert Repo.get!(Recake.Jobs.Request, request.id).recruit_count == 3
    end

    test "shows error when request recruit count > job recruit count", %{conn: conn, request: request, job: job} do
      Repo.update!(Ecto.Changeset.change(job, recruit_count: 2))

      conn = put(conn, Routes.job_request_path(conn, :update, request.id), %{"available" => "", "recruit_count" => "3"})
      assert get_flash(conn, :error) == gettext("Your number of available recruits can't exceed the number requested")

      current_request = Repo.get!(Recake.Jobs.Request, request.id)
      assert current_request.recruit_count == 1
      assert current_request.state == "pending"
    end

    test "does not resolve other user's requests", %{conn: conn, job: job} do
      other_user = user_fixture()
      request = job_request_fixture(other_user, job)

      conn = put(conn, Routes.job_request_path(conn, :update, request.id), %{"available" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :success)

      assert Repo.get!(Recake.Jobs.Request, request.id).state == "pending"

      conn = put(conn, Routes.job_request_path(conn, :update, request.id), %{"unavailable" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :info)

      assert Repo.get!(Recake.Jobs.Request, request.id).state == "pending"
    end

    test "does nothing to already accepted requests", %{conn: conn, request: request} do
      accepted_request =
        request
        |> Ecto.Changeset.change(state: "available")
        |> Repo.update!()

      conn = put(conn, Routes.job_request_path(conn, :update, accepted_request.id), %{"available" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(Recake.Jobs.Request, accepted_request.id).state == "available"

      conn = put(conn, Routes.job_request_path(conn, :update, accepted_request.id), %{"unavailable" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(Recake.Jobs.Request, accepted_request.id).state == "available"
    end

    test "does nothing to already rejected requests", %{conn: conn, request: request} do
      rejected_request =
        request
        |> Ecto.Changeset.change(state: "unavailable")
        |> Repo.update!()

      conn = put(conn, Routes.job_request_path(conn, :update, rejected_request.id), %{"available" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(Recake.Jobs.Request, rejected_request.id).state == "unavailable"

      conn = put(conn, Routes.job_request_path(conn, :update, rejected_request.id), %{"unavailable" => ""})
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(Recake.Jobs.Request, rejected_request.id).state == "unavailable"
    end

    test "does nothing on invalid resolution", %{conn: conn, request: request} do
      conn = put(conn, Routes.job_request_path(conn, :update, request.id))
      assert redirected_to(conn) == Routes.inbox_path(conn, :index)
      refute get_flash(conn, :success)
      refute get_flash(conn, :info)

      assert Repo.get!(Recake.Jobs.Request, request.id).state == "pending"
    end
  end
end
