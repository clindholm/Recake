defmodule RecakeWeb.UserRegistrationControllerTest do
  use RecakeWeb.ConnCase, async: true

  import Recake.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration form with valid invitation token", %{conn: conn} do
      token = invitation_fixture()

      conn
      |> get(Routes.user_registration_path(conn, :new, token: token))
      |> html_document()
      |> assert_selector_content("h1", gettext("Register"))
      |> assert_form(Routes.user_registration_path(conn, :create, token: token), [
        "input[name=\"user[email]\"]",
        "input[name=\"user[password]\"][type=password]",
        "input[name=\"user[company]\"",
        "input[name=\"user[phone]\"",
        "button[type=submit]"
      ])
    end

    test "does not render form with no token", %{conn: conn} do
      conn
      |> get(Routes.user_registration_path(conn, :new))
      |> html_document()
      |> assert_selector_content(
        ".info",
        gettext("You need an invitation to register a new account")
      )
      |> refute_selector("form")
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> login_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/register" do
    setup %{conn: conn} do
      %{
        token: invitation_fixture(),
        conn: conn
      }
    end

    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn, token: token} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create, token: token), %{
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
      assert conn.status == 200
    end

    test "render errors for invalid data", %{conn: conn, token: token} do
      conn
      |> post(Routes.user_registration_path(conn, :create, token: token), %{
        "user" => %{"email" => "with spaces", "password" => "invalid"}
      })
      |> html_document()
      |> assert_selector_content("h1", gettext("Register"))
      |> assert_selector_content(
        ".validation-error",
        dgettext("errors", "must include @ sign and no spaces")
      )
      |> assert_selector_content(
        ".validation-error",
        dngettext(
          "errors",
          "should be at least %{count} character(s)",
          "should be at least %{count} character(s)",
          8
        )
      )
    end

    test "crashes on missing user params", %{conn: conn, token: token} do
      assert_raise Phoenix.ActionClauseError, fn ->
        post(conn, Routes.user_registration_path(conn, :create, token: token), %{})
      end
    end

    test "crashes on missing token", %{conn: conn} do
      assert_raise Phoenix.ActionClauseError, fn ->
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "email@test.com", "password" => "password"}
        })
      end
    end
  end
end
