defmodule Recake.AccountsTest do
  use Recake.DataCase, async: true

  import RecakeWeb.Gettext
  import Recake.AccountsFixtures
  import Recake.JobsFixtures

  alias Recake.Accounts
  alias Recake.Accounts.{User, UserToken, Invitation}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "password")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(123)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    setup do
      %{
        token: invitation_fixture()
      }
    end

    test "fails on invalid token" do
      assert {:error, :invalid_token} = Accounts.register_user("Invalid", %{
        email: unique_user_email(),
        password: valid_user_password(),
        company: "C",
        phone: "123",
        organization_number: "123",
        contact_name: "CN",
      })
    end

    test "fails on used token", %{token: token} do
      # Use token
      Repo.delete_all(Invitation)

      email = unique_user_email()

      assert {:error, :invalid_token} =
               Accounts.register_user(token, %{
                 email: email,
                 password: valid_user_password(),
                 company: "C",
                 phone: "123",
                 organization_number: "123",
                 contact_name: "CN",
               })
    end

    test "requires fields to be set", %{token: token} do
      {:error, changeset} = Accounts.register_user(token, %{})

      error = dgettext("errors", "can't be blank")

      assert %{
               company: [^error],
               contact_name: [^error],
               organization_number: [^error],
               phone: [^error],
               password: [^error],
               email: [^error]
             } = errors_on(changeset)
    end

    test "validates email and password when given", %{token: token} do
      {:error, changeset} =
        Accounts.register_user(token, %{email: "not valid", password: "invalid"})

      email_error = dgettext("errors", "must include @ sign and no spaces")

      password_error =
        dngettext(
          "errors",
          "should be at least %{count} character(s)",
          "should be at least %{count} character(s)",
          8
        )

      assert %{
               email: [^email_error],
               password: [^password_error]
             } = errors_on(changeset)
    end

    test "validates maximum values for e-mail and password for security", %{token: token} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(token, %{email: too_long, password: too_long})

      assert dngettext(
               "errors",
               "should be at most %{count} character(s)",
               "should be at most %{count} character(s)",
               160
             ) in errors_on(changeset).email

      assert dngettext(
               "errors",
               "should be at most %{count} character(s)",
               "should be at most %{count} character(s)",
               80
             ) in errors_on(changeset).password
    end

    test "validates e-mail uniqueness", %{token: token} do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(token, %{email: email})
      assert dgettext("errors", "has already been taken") in errors_on(changeset).email

      # Now try with the upper cased e-mail too, to check that email case is ignored.
      token = invitation_fixture()
      {:error, changeset} = Accounts.register_user(token, %{email: String.upcase(email)})
      assert dgettext("errors", "has already been taken") in errors_on(changeset).email
    end

    test "downcases email", %{token: token} do
      email = "UPCASE@EXAMPLE.COM"

      {:ok, user} =
        Accounts.register_user(token, %{
          email: email,
          password: valid_user_password(),
          company: "C",
          organization_number: "123456",
          contact_name: "C",
          phone: "123"
        })

      assert user.email == "upcase@example.com"
    end

    test "registers users with a hashed password", %{token: token} do
      email = unique_user_email()

      {:ok, user} =
        Accounts.register_user(token, %{
          email: email,
          password: valid_user_password(),
          company: "C",
          organization_number: "123456",
          contact_name: "C",
          phone: "123"
        })

      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end

    test "deletes invitation", %{token: token} do
      email = unique_user_email()

      {:ok, _user} =
        Accounts.register_user(token, %{
          email: email,
          password: valid_user_password(),
          company: "C",
          organization_number: "123456",
          contact_name: "C",
          phone: "123",
        })

      refute Accounts.verify_invitation(token)
    end

    test "creates a job_request if a newly created, ongoing job is available", %{token: token} do
      previous_user = user_fixture()
      previous_job = job_fixture(previous_user)

      email = unique_user_email()

      {:ok, user} =
        Accounts.register_user(token, %{
          email: email,
          password: valid_user_password(),
          company: "C",
          organization_number: "123456",
          contact_name: "C",
          phone: "123",
        })

      user = Recake.Repo.preload(user, :job_requests)
      assert List.first(user.job_requests).job_id == previous_job.id
    end
  end

  describe "change_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_registration(%User{})
      assert changeset.required == [:password, :email, :company, :organization_number, :contact_name, :phone]
    end
  end

  describe "change_user_profile/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_profile(%User{})
      assert changeset.required == [:company, :organization_number, :contact_name, :phone]
    end
  end

  describe "update_user_profile/3" do
    setup do
      %{user: user_fixture()}
    end

    test "updates profile", %{user: user} do
      {:ok, user} =
        Accounts.update_user_profile(user, %{
          company: "updated company",
          organization_number: "updated number",
          contact_name: "updated contact name",
          phone: "updated phone",
        })

      user = Accounts.get_user!(user.id)
      assert user.company == "updated company"
      assert user.organization_number == "updated number"
      assert user.contact_name == "updated contact name"
      assert user.phone == "updated phone"
    end
  end


  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_user_email/3" do
    setup do
      %{user: user_fixture()}
    end

    test "requires email to change", %{user: user} do
      {:error, changeset} = Accounts.apply_user_email(user, valid_user_password(), %{})

      email_error = dgettext("errors", "did not change")
      assert %{email: [^email_error]} = errors_on(changeset)
    end

    test "validates email", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: "not valid"})

      email_error = dgettext("errors", "must include @ sign and no spaces")
      assert %{email: [^email_error]} = errors_on(changeset)
    end

    test "validates maximum value for e-mail for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: too_long})

      assert dngettext(
               "errors",
               "should be at most %{count} character(s)",
               "should be at most %{count} character(s)",
               160
             ) in errors_on(changeset).email
    end

    test "validates e-mail uniqueness", %{user: user} do
      %{email: email} = user_fixture()

      {:error, changeset} =
        Accounts.apply_user_email(user, valid_user_password(), %{email: email})

      assert dgettext("errors", "has already been taken") in errors_on(changeset).email
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.apply_user_email(user, "invalid", %{email: unique_user_email()})

      password_error = dgettext("errors", "is not valid")
      assert %{current_password: [^password_error]} = errors_on(changeset)
    end

    test "applies the e-mail without persisting it", %{user: user} do
      email = unique_user_email()
      {:ok, user} = Accounts.apply_user_email(user, valid_user_password(), %{email: email})
      assert user.email == email
      assert Accounts.get_user!(user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the e-mail with a valid token", %{user: user, token: token, email: email} do
      assert Accounts.update_user_email(user, token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update e-mail with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update e-mail if user e-mail changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update e-mail if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end
  end

  describe "update_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "invalid",
          password_confirmation: "another"
        })

      password_error =
        dngettext(
          "errors",
          "should be at least %{count} character(s)",
          "should be at least %{count} character(s)",
          8
        )

      password_confirmation_error = dgettext("errors", "does not match password")

      assert %{
               password: [^password_error],
               password_confirmation: [^password_confirmation_error]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, valid_user_password(), %{password: too_long})

      assert dngettext(
               "errors",
               "should be at most %{count} character(s)",
               "should be at most %{count} character(s)",
               80
             ) in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: valid_user_password()})

      error_msg = dgettext("errors", "is not valid")
      assert %{current_password: [^error_msg]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, valid_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_session_token(user)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/2" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "confirms the e-mail with a valid token", %{user: user, token: token} do
      assert Accounts.confirm_user(token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm with invalid token", %{user: user} do
      assert Accounts.confirm_user("oops") == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not confirm e-mail if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_user(token) == :error
      refute Repo.get!(User, user.id).confirmed_at
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "get_user_by_reset_password_token/2" do
    setup do
      user = user_fixture()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, token: token}
    end

    test "returns the user with valid token", %{user: %{id: id}, token: token} do
      assert %User{id: ^id} = Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return the user with invalid token", %{user: user} do
      refute Accounts.get_user_by_reset_password_token("oops")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return the user if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_reset_password_token(token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "reset_user_password/3" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "invalid",
          password_confirmation: "another"
        })

      password_error =
        dngettext(
          "errors",
          "should be at least %{count} character(s)",
          "should be at least %{count} character(s)",
          8
        )

      password_confirmation_error = dgettext("errors", "does not match password")

      assert %{
               password: [^password_error],
               password_confirmation: [^password_confirmation_error]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_user_password(user, %{password: too_long})

      assert dngettext(
               "errors",
               "should be at most %{count} character(s)",
               "should be at most %{count} character(s)",
               80
             ) in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"})
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_session_token(user)
      {:ok, _} = Accounts.reset_user_password(user, %{password: "new valid password"})
      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%User{password: "password"}) =~ "password: \"password\""
    end
  end

  describe "list_invitations/0" do
    test "returns all invitations, newest first" do
      Accounts.create_invitation()
      Accounts.create_invitation()

      invitations = Accounts.list_invitations()

      assert Enum.count(invitations) == 2
      assert Enum.sort_by(invitations, &(&1.inserted_at), :desc) == invitations
    end
  end

  describe "create_invitation/0" do
    test "returns encoded token" do
      token = Accounts.create_invitation()
      token = Base.url_decode64!(token, padding: false)

      assert Repo.one(from i in Invitation, where: i.token == ^token)
    end

    test "associates optional creator" do
      creator = user_fixture()

      token = Accounts.create_invitation(creator.id)
      token = Base.url_decode64!(token, padding: false)

      invitation = Repo.one(from i in Invitation, where: i.token == ^token)
      assert invitation.creator_id == creator.id
    end
  end

  describe "verify_invitation/0" do
    test "verifies existing token" do
      token = Accounts.create_invitation()

      assert Accounts.verify_invitation(token)
    end

    test "missing token is not verified" do
      token =
        :crypto.strong_rand_bytes(32)
        |> Base.url_encode64(padding: false)

      refute Accounts.verify_invitation(token)
    end
  end
end
