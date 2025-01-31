defmodule RecakeWeb.UserSessionController do
  use RecakeWeb, :controller

  alias Recake.Accounts
  alias RecakeWeb.UserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.login_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: gettext("Invalid e-mail or password"))
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:success, gettext("Logged out successfully"))
    |> UserAuth.logout_user()
  end
end
