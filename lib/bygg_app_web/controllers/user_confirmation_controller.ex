defmodule ByggAppWeb.UserConfirmationController do
  use ByggAppWeb, :controller

  alias ByggApp.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &Routes.user_confirmation_url(conn, :confirm, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      gettext("If your e-mail is in our system and it has not been confirmed yet, you will receive an e-mail with instructions shortly.")
    )
    |> redirect(to: "/")
  end

  def confirm(conn, %{"token" => token}) do
    case Accounts.confirm_user(token) do
      :ok ->
        conn
        |> put_flash(:info, gettext("Account confirmed successfully"))
        |> redirect(to: "/")

      :error ->
        conn
        |> put_flash(:error, gettext("Confirmation token is invalid or it has expired"))
        |> redirect(to: "/")
    end
  end
end
