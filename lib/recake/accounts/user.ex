defmodule Recake.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Utils.Changeset
  import RecakeWeb.Gettext

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :company, :string
    field :organization_number, :string
    field :contact_name, :string
    field :phone, :string

    field :admin_permissions, {:array, :string}, default: []

    has_many(:job_requests, Recake.Jobs.Request, foreign_key: :recipient_id)

    timestamps()
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :company, :organization_number, :contact_name, :phone])
    |> validate_required([:company, :organization_number, :contact_name, :phone])
    |> validate_email()
    |> validate_password()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: dgettext("errors", "must include @ sign and no spaces"))
    |> validate_length(:email, max: 160)
    |> downcase_field(:email)
    |> unsafe_validate_unique(:email, Recake.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 80)
    |> prepare_changes(&maybe_hash_password/1)
  end

  defp maybe_hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Pbkdf2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:company, :organization_number, :contact_name, :phone])
    |> validate_required([:company, :organization_number, :contact_name, :phone])
  end

  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, dgettext("errors", "did not change"))
    end
  end

  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: dgettext("errors", "does not match password"))
    |> validate_password()
  end

  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def valid_password?(%Recake.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Pbkdf2.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Pbkdf2.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, dgettext("errors", "is not valid"))
    end
  end
end
