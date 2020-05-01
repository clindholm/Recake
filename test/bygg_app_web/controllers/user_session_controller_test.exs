defmodule ByggAppWeb.UserSessionControllerTest do
  use ByggAppWeb.ConnCase, async: true

  import ByggApp.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/login" do
    test "renders login page", %{conn: conn} do
      conn
      |> get(Routes.user_session_path(conn, :new))
      |> html_document()
      |> assert_selector_content("h1", gettext("Login"))
      |> assert_form(Routes.user_session_path(conn, :create), [
        "input[name=\"user[email]\"]",
        "input[name=\"user[password]\"][type=password]",
        "button[type=\"submit\"]",
      ])
    end

    test "renders flash", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})

      assert_render_flash(conn, & get(&1, Routes.user_session_path(conn, :new)), :info)
      assert_render_flash(conn, & get(&1, Routes.user_session_path(conn, :new)), :error)
      assert_render_flash(conn, & get(&1, Routes.user_session_path(conn, :new)), :success)
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> login_user(user) |> get(Routes.user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/login" do
    test "logs the user in", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request
      conn = get(conn, "/")
      assert conn.status == 200
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{
            "email" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn
      |> post(Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })
      |> html_document()
      |> assert_selector_content(".alert-error", gettext("Invalid e-mail or password"))
    end
  end

  describe "DELETE /users/logout" do
    test "redirects if not logged in", %{conn: conn} do
      conn = delete(conn, Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/users/login"
    end

    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> login_user(user) |> delete(Routes.user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert get_flash(conn, :success) && get_flash(conn, :success) =~ gettext("Logged out successfully")
    end
  end
end
