defmodule ByggAppWeb.UserRegistrationControllerTest do
  use ByggAppWeb.ConnCase, async: true

  import ByggApp.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "#{gettext "Register"}</h1>"
      assert response =~ "<form action=\"#{Routes.user_registration_path(conn, :create)}\""
      assert response =~ "name=\"user[email]\""
      assert response =~ "name=\"user[password]\""
      assert response =~ "name=\"user[company]\""
      assert response =~ "name=\"user[phone]\""
      assert response =~ "type=\"submit\""
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> login_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{
            "email" => email,
            "password" => valid_user_password(),
            "company" => "Company name",
            "phone" => "12334556"
          }
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request
      conn = get(conn, "/")
      assert html_response(conn, 200)
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "invalid"}
        })

      response = html_response(conn, 200)
      assert response =~ "#{gettext "Register"}</h1>"
      assert response =~ dgettext("errors", "must include @ sign and no spaces")
      assert response =~ dngettext("errors", "should be at least %{count} character(s)", "should be at least %{count} character(s)", 8)
    end
  end
end
