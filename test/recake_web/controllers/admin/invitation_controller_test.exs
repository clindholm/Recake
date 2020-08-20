defmodule RecakeWeb.Admin.InvitationControllerTest do
  use RecakeWeb.ConnCase, async: true

  import Recake.AccountsFixtures

  alias Recake.Repo
  alias Recake.Accounts.Invitation

  setup %{conn: conn} do
    user = user_fixture(%{admin_permissions: ["invitations"]})

    conn =
      conn
      |> login_user(user)

    %{
      conn: conn,
      user: user
    }
  end

  describe "GET /admin/invitations" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.admin_invitation_path(conn, :index))
      assert redirected_to(conn) == "/users/login"
    end

    test "redirects if user does not have permission", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> login_user(user)

      conn = get(conn, Routes.admin_invitation_path(conn, :index))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /admin/invitations" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = post(conn, Routes.admin_invitation_path(conn, :create))
      assert redirected_to(conn) == "/users/login"
    end

    test "redirects if user does not have permission", %{conn: conn} do
      user = user_fixture()

      conn =
        conn
        |> login_user(user)

      conn = post(conn, Routes.admin_invitation_path(conn, :create))
      assert redirected_to(conn) == "/"
    end

    test "creates invitation", %{conn: conn, user: user} do
      _conn = post(conn, Routes.admin_invitation_path(conn, :create))

      invitation = Repo.one(Invitation)

      assert invitation
      assert invitation.creator_id == user.id
    end
  end

end
