defmodule ByggAppWeb.UserSessionControllerTest do
  use ByggAppWeb.ConnCase, async: true

  import ByggApp.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/login" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, Routes.user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "Login</h1>"
      assert response =~ "<form action=\"#{Routes.user_session_path(conn, :create)}\""
      assert response =~ "name=\"user[email]\""
      assert response =~ "name=\"user[password]\""
      assert response =~ "type=\"submit\""
    end

    test "renders info flash", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> put_flash(:info, "Info flash")
        |> get(Routes.user_session_path(conn, :new))

      response = html_response(conn, 200)
      assert response =~ "Info flash"
    end

    test "renders error flash", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> put_flash(:error, "Error flash")
        |> get(Routes.user_session_path(conn, :new))

      response = html_response(conn, 200)
      assert response =~ "Error flash"
    end

    test "renders success flash", %{conn: conn} do
      conn =
        conn
        |> init_test_session(%{})
        |> fetch_flash()
        |> put_flash(:success, "Success flash")
        |> get(Routes.user_session_path(conn, :new))

      response = html_response(conn, 200)
      assert response =~ "Success flash"
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
      _response = html_response(conn, 200)
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
      conn =
        post(conn, Routes.user_session_path(conn, :create), %{
          "user" => %{"email" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "Invalid e-mail or password"
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
      assert get_flash(conn, :success) && get_flash(conn, :success) =~ "Logged out successfully"
    end
  end
end
