defmodule RecakeWeb.UserSettingsController do
  use RecakeWeb, :controller

  alias Recake.Accounts
  alias RecakeWeb.UserAuth

  plug :page_header, gettext("Settings")
  plug :assign_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update_profile(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_profile(user, password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:success, gettext("Profile updated successfully"))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", profile_changeset: changeset)
    end
  end

  def update_password(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:success, gettext("Password updated successfully"))
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.login_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def update_email(conn, %{"current_password" => password, "user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, &1)
        )

        conn
        |> put_flash(
          :info,
          gettext("A link to confirm your e-mail has been sent to the new address.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:success, gettext("E-mail updated successfully"))
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      :error ->
        conn
        |> put_flash(:error, gettext("E-mail update url is invalid. Try updating your e-mail again below."))
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  defp assign_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:profile_changeset, Accounts.change_user_profile(user))
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
