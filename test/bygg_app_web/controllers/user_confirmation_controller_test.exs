defmodule ByggAppWeb.UserConfirmationControllerTest do
  use ByggAppWeb.ConnCase, async: true

  alias ByggApp.Accounts
  alias ByggApp.Repo
  import ByggApp.AccountsFixtures

  setup do
    %{user: user_fixture()}
  end

  describe "GET /users/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn
      |> get(Routes.user_confirmation_path(conn, :new))
      |> html_document()
      |> assert_selector_content("h1", "Resend confirmation instructions")
    end
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, user: user} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ gettext("If your e-mail is in our system and it has not been confirmed yet, you will receive an e-mail with instructions shortly.")
      assert Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "confirm"
    end

    test "does not send confirmation token if account is confirmed", %{conn: conn, user: user} do
      Repo.update!(Accounts.User.confirm_changeset(user))

      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ gettext("If your e-mail is in our system and it has not been confirmed yet, you will receive an e-mail with instructions shortly.")
      refute Repo.get_by(Accounts.UserToken, user_id: user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.user_confirmation_path(conn, :create), %{
          "user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ gettext("If your e-mail is in our system and it has not been confirmed yet, you will receive an e-mail with instructions shortly.")
      assert Repo.all(Accounts.UserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ gettext("Account confirmed successfully")
      assert Accounts.get_user!(user.id).confirmed_at
      refute get_session(conn, :user_token)
      assert Repo.all(Accounts.UserToken) == []

      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ gettext("Confirmation token is invalid or it has expired")
    end

    test "does not confirm email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ gettext("Confirmation token is invalid or it has expired")
      refute Accounts.get_user!(user.id).confirmed_at
    end
  end
end
