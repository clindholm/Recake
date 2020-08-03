defmodule RecakeWeb.UserSettingsControllerTest do
  use RecakeWeb.ConnCase, async: true

  alias Recake.Accounts
  import Recake.AccountsFixtures

  setup :register_and_login_user

  describe "GET /users/settings" do
    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == "/users/login"
    end

    test "renders flash", %{conn: conn} do
      assert_render_flash(conn, &get(&1, Routes.user_settings_path(conn, :edit)), :success)
      assert_render_flash(conn, &get(&1, Routes.user_settings_path(conn, :edit)), :error)
      assert_render_flash(conn, &get(&1, Routes.user_settings_path(conn, :edit)), :info)
    end

    test "renders settings page", %{conn: conn} do
      conn
      |> get(Routes.user_settings_path(conn, :edit))
      |> html_document()
      |> assert_form(Routes.user_settings_path(conn, :update_profile), [
        "input[name=\"user[company]\"]",
        "input[name=\"user[organization_number]\"]",
        "input[name=\"user[contact_name]\"]",
        "input[name=\"user[phone]\"]",
        "input[name=\"current_password\"][type=password]",
        "button[type=\"submit\"]"
      ])
      |> assert_form(Routes.user_settings_path(conn, :update_password), [
        "input[name=\"user[password]\"][type=password]",
        "input[name=\"user[password_confirmation]\"][type=password]",
        "input[name=\"current_password\"][type=password]",
        "button[type=\"submit\"]"
      ])
      |> assert_form(Routes.user_settings_path(conn, :update_email), [
        "input[name=\"user[email]\"]",
        "input[name=\"current_password\"][type=password]",
        "button[type=\"submit\"]"
      ])
    end
  end

  describe "PUT /users/settings/update_profile" do
    test "updates user profile", %{conn: conn, user: user} do
      new_profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "current_password" => valid_user_password(),
          "user" => %{
            "company" => "updated company",
            "organization_number" => "updated number",
            "contact_name" => "updated contact name",
            "phone" => "updated phone",
          }
        })

      assert redirected_to(new_profile_conn) == "/users/settings"
      assert get_flash(new_profile_conn, :success) =~ gettext("Profile updated successfully")

      user = Accounts.get_user!(user.id)
      assert user.company == "updated company"
      assert user.organization_number == "updated number"
      assert user.contact_name == "updated contact name"
      assert user.phone == "updated phone"
    end

    test "does not update profile on invalid data", %{conn: conn} do
      old_profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "current_password" => "invalid",
          "user" => %{
            "company" => "",
          }
        })

      old_profile_conn
      |> html_document()
      |> assert_selector_content(".validation-error", dgettext("errors", "can't be blank"))
      |> assert_selector_content(".validation-error", dgettext("errors", "is not valid"))
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

      old_password_conn
      |> html_document()
      |> assert_selector_content(".validation-error", dngettext("errors", "should be at least %{count} character(s)", "should be at least %{count} character(s)", 8))
      |> assert_selector_content(".validation-error", dgettext("errors", "does not match password"))
      |> assert_selector_content(".validation-error", dgettext("errors", "is not valid"))

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
      conn
      |> put(Routes.user_settings_path(conn, :update_email), %{
        "current_password" => "invalid",
        "user" => %{"email" => "with spaces"}
      })
      |> html_document()
      |> assert_selector_content(".validation-error", dgettext("errors", "must include @ sign and no spaces"))
      |> assert_selector_content(".validation-error", dgettext("errors", "is not valid"))
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
