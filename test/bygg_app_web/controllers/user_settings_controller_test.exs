defmodule ByggAppWeb.UserSettingsControllerTest do
  use ByggAppWeb.ConnCase, async: true

  alias ByggApp.Accounts
  import ByggApp.AccountsFixtures

  setup :register_and_login_user

  describe "GET /users/settings" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders success flash", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:success, "Success flash")
        |> get(Routes.user_settings_path(conn, :edit))

      response = html_response(conn, 200)
      assert response =~ "Success flash"
    end

    test "renders error flash", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:error, "Error flash")
        |> get(Routes.user_settings_path(conn, :edit))

      response = html_response(conn, 200)
      assert response =~ "Error flash"
    end

    test "renders info flash", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:info, "Info flash")
        |> get(Routes.user_settings_path(conn, :edit))

      response = html_response(conn, 200)
      assert response =~ "Info flash"
    end

    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert_section_header response, gettext("Settings")
      assert response =~ "<form action=\"#{Routes.user_settings_path(conn, :update_password)}\""
      assert response =~ "<form action=\"#{Routes.user_settings_path(conn, :update_email)}\""
      assert response =~ "name=\"user[password]\""
      assert response =~ "name=\"current_password\""
      assert response =~ "name=\"user[password_confirmation]\""
      assert response =~ "name=\"user[email]\""
      assert response =~ "type=\"submit\""
    end
  end

  describe "PUT /users/settings/update_password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == "/users/settings"
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert get_flash(new_password_conn, :success) =~ gettext("Password updated successfully")
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "invalid",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert_section_header response, gettext("Settings")
      assert response =~ dngettext("errors", "should be at least %{count} character(s)", "should be at least %{count} character(s)", 8)
      assert response =~ dgettext("errors", "does not match password")
      assert response =~ dgettext("errors", "is not valid")

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings/update_email" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == "/users/settings"
      assert get_flash(conn, :info) =~ gettext("A link to confirm your e-mail has been sent to the new address.")
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert_section_header response, gettext("Settings")
      assert response =~ dgettext("errors", "must include @ sign and no spaces")
      assert response =~ dgettext("errors", "is not valid")
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == "/users/settings"
      assert get_flash(conn, :success) =~ gettext("E-mail updated successfully")
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == "/users/settings"
      assert get_flash(conn, :error) =~ gettext("E-mail update url is invalid. Try updating your e-mail again below.")
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == "/users/settings"
      assert get_flash(conn, :error) =~ gettext("E-mail update url is invalid. Try updating your e-mail again below.")
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == "/users/login"
    end
  end
end
