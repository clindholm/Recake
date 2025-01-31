defmodule Recake.Accounts do
  import Ecto.Query, only: [from: 2]

  alias Recake.Repo
  alias Recake.Accounts.{User, UserToken, UserNotifier, Invitation}

  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  def get_user!(id), do: Repo.get!(User, id)

  def register_user(invitation_token, attrs) do
    changeset = User.registration_changeset(%User{}, attrs)

    Ecto.Multi.new()
    |> Ecto.Multi.run(:invitation, fn repo, _ ->
      case Base.url_decode64(invitation_token, padding: false) do
        {:ok, token} ->
          from(i in Invitation,
            where: i.token == ^token
          )
          |> repo.delete_all()
          |> case do
            {1, _} -> {:ok, :ok}
            _ -> {:error, :invalid_token}
          end

        :error ->
          {:error, :invalid_token}
      end
    end)
    |> Ecto.Multi.insert(:user, changeset)
    |> Ecto.Multi.run(:job_request, fn repo, %{user: user} ->
      jobs =
        from(j in Recake.Jobs.Job,
          where: j.state == ^"active",
          order_by: [desc: j.inserted_at],
          limit: 1
        )
        |> Recake.Repo.all()

      case jobs do
        [job] ->
          repo.insert(%Recake.Jobs.Request{recipient_id: user.id, job_id: job.id})

          {:ok, :request_created}

        [] ->
          {:ok, :request_not_created}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :invitation, _, _} -> {:error, :invalid_token}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_user_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} =
      UserToken.build_user_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end

  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def generate_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_user_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_user_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, _} <- Repo.transaction(confirm_user_multi(user)) do
      :ok
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_user_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_user_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def list_invitations() do
    from(i in Invitation,
      order_by: [desc: i.inserted_at],
      preload: :creator
    )
    |> Repo.all()
  end

  def create_invitation(creator_id \\ nil) do
    {token, invitation} = Invitation.invitation(creator_id)

    Repo.insert!(invitation)

    token
  end

  def verify_invitation(token) do
    case Base.url_decode64(token, padding: false) do
      {:ok, token} ->
        q = from(i in Invitation, where: i.token == ^token)
        Repo.exists?(q)

      :error ->
        false
    end
  end
end
