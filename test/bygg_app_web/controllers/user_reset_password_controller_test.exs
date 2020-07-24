defmodule RecakeWeb.UserResetPasswordControllerTest do
  use RecakeWeb.ConnCase, async: true

  alias Recake.Accounts
  alias Recake.Repo
  import Recake.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn
      |> get(Routes.user_reset_password_path(conn, :new))
      |> html_document()
      |> assert_selector_content("h1", gettext("Forgot your password?"))
      |> assert_form(Routes.user_reset_password_path(conn, :create), [
        "input[name=\"user[email]\"]",
        "button[type=\"submit\"]"
      ])
    end

    test "renders error flash", %{conn: conn} do
      conn
      |> init_test_session(%{})
      |> assert_render_flash(&get(&1, Routes.user_reset_password_path(conn, :new)), :error)
    end
  end

  describe "POST /users/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/users/login"

      assert get_flash(conn, :info) =~
               gettext(
                 "You will receive instructions to reset your password to your e-mail shortly."
               )

      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/users/login"

      assert get_flash(conn, :info) =~
               gettext(
                 "You will receive instructions to reset your password to your e-mail shortly."
               )

      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/reset_password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn
      |> get(Routes.user_reset_password_path(conn, :edit, token))
      |> html_document()
      |> assert_selector_content("h1", gettext("Reset password"))
      |> assert_form(Routes.user_reset_password_path(conn, :update, token), [
        "input[name=\"user[password]\"]",
        "input[name=\"user[password_confirmation]\"]",
        "button[type=\"submit\"]"
      ])
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.user_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/users/reset_password"

      assert get_flash(conn, :error) =~
               gettext("Reset password link has expired. Send a new link below.")
    end
  end

  describe "PUT /users/reset_password/:token" do
    setup %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, user: user, token: token} do
      conn =
        put(conn, Routes.user_reset_password_path(conn, :update, token), %{
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == "/users/login"
      refute get_session(conn, :user_token)

      assert get_flash(conn, :success) &&
               get_flash(conn, :success) =~ gettext("Password reset successfully")

      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn
      |> put(Routes.user_reset_password_path(conn, :update, token), %{
        "user" => %{
          "password" => "invalid",
          "password_confirmation" => "does not match"
        }
      })
      |> html_document()
      |> assert_selector_content("h1", gettext("Reset password"))
      |> assert_selector_content(
        ".validation-error",
        dngettext(
          "errors",
          "should be at least %{count} character(s)",
          "should be at least %{count} character(s)",
          8
        )
      )
      |> assert_selector_content(
        ".validation-error",
        dgettext("errors", "does not match password")
      )
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.user_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/users/reset_password"

      assert get_flash(conn, :error) =~
               gettext("Reset password link has expired. Send a new link below.")
    end
  end
end
