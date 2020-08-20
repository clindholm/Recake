defmodule RecakeWeb.Admin.InvitationController do
  use RecakeWeb, :controller

  import RecakeWeb.UserAuth

  alias Recake.Accounts

  plug :require_authorized_user, "invitations"

  def index(conn, _) do
    invitations = Accounts.list_invitations()

    conn
    |> render("index.html", invitations: invitations)
  end

  def create(conn, _) do
    Accounts.create_invitation(conn.assigns.current_user.id)

    conn
    |> put_flash(:success, gettext("Invitation created"))
    |> redirect(to: Routes.admin_invitation_path(conn, :index))
  end
end
