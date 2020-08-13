defmodule ByggAppWeb.LayoutTest do
  use RecakeWeb.ConnCase, async: true

  import Recake.AccountsFixtures

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

  describe "App layout" do
    test "renders admin navigation only for admins", %{conn: conn, user: user} do
      conn
      |> get(Routes.inbox_path(conn, :index))
      |> html_document()
      |> refute_selector(".admin-link")

      user
      |> Ecto.Changeset.change(admin_permissions: ["invitations"])
      |> Repo.update!()

      conn
      |> get(Routes.inbox_path(conn, :index))
      |> html_document()
      |> assert_selector(".admin-link")
    end
  end
end
