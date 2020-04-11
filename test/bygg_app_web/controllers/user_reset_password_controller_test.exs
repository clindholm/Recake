defmodule ByggAppWeb.UserResetPasswordControllerTest do
  use ByggAppWeb.ConnCase, async: true

  alias ByggApp.Accounts
  alias ByggApp.Repo
  import ByggApp.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.user_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Forgot your password?</h1>"
      assert response =~ "<form action=\"#{Routes.user_reset_password_path(conn, :create)}\""
      assert response =~ "name=\"user[email]\""
      assert response =~ "type=\"submit\""
    end

    test "renders error flash", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> put_flash(:error, "Error flash")
        |> get(Routes.user_reset_password_path(conn, :new))

      response = html_response(conn, 200)
      assert response =~ "Error flash"
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
      assert get_flash(conn, :info) =~ "You will receive instructions to reset your password to your e-mail shortly."
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_reset_password_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/users/login"
      assert get_flash(conn, :info) =~ "You will receive instructions to reset your password to your e-mail shortly."
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
      conn = get(conn, Routes.user_reset_password_path(conn, :edit, token))
      response = html_response(conn, 200)
      assert response =~ "Reset password</h1>"
      assert response =~ "<form action=\"#{Routes.user_reset_password_path(conn, :update, token)}\""
      assert response =~ "name=\"user[password]\""
      assert response =~ "name=\"user[password_confirmation]\""
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.user_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/users/reset_password"
      assert get_flash(conn, :error) =~ "Reset password link has expired. Send a new link below."
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
      assert get_flash(conn, :success) && get_flash(conn, :success)  =~ "Password reset successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.user_reset_password_path(conn, :update, token), %{
          "user" => %{
            "password" => "invalid",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "Reset password</h1>"
      assert response =~ "should be at least 8 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.user_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/users/reset_password"
      assert get_flash(conn, :error) =~ "Reset password link has expired. Send a new link below."
    end
  end
end
