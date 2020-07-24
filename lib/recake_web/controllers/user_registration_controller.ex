defmodule RecakeWeb.UserRegistrationController do
  use RecakeWeb, :controller

  alias Recake.Accounts
  alias Recake.Accounts.User
  alias RecakeWeb.UserAuth

  def new(conn, params) do
    token = params["token"]

    if token && Accounts.verify_invitation(token) do
      changeset = Accounts.change_user_registration(%User{})
      render(conn, "new.html", changeset: changeset, token: token)
    else
      render(conn, "invalid_token.html")
    end
  end

  def create(conn, %{"user" => user_params, "token" => invitation_token}) do
    case Accounts.register_user(invitation_token, user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &Routes.user_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, gettext("User created successfully"))
        |> UserAuth.login_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset, token: invitation_token)
    end
  end
end
